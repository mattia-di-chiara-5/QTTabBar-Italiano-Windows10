// SPDX-License-Identifier: GPL-3.0-only
// Resource data editor for the pinned upstream resource-only translation DLL.
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Runtime.Serialization;
using System.Runtime.Serialization.Json;
using System.Text;
[DataContract] public sealed class Replacement {
 [DataMember(IsRequired=true)]public int Id;
 [DataMember(IsRequired=true)]public string Symbol;
 [DataMember(IsRequired=true)]public string Original;
 [DataMember(IsRequired=true)]public string Italian;
}
internal static class ResourceLocalizer {
 private const ushort ItalianLanguage=1040;
 private static readonly IntPtr StringType=new IntPtr(6);
 [DllImport("kernel32.dll",CharSet=CharSet.Unicode,SetLastError=true)]private static extern IntPtr LoadLibraryEx(string file,IntPtr reserved,uint flags);
 [DllImport("kernel32.dll",SetLastError=true)]private static extern bool FreeLibrary(IntPtr module);
 [DllImport("kernel32.dll",CharSet=CharSet.Unicode,SetLastError=true)]private static extern IntPtr FindResourceEx(IntPtr module,IntPtr type,IntPtr name,ushort language);
 [DllImport("kernel32.dll",SetLastError=true)]private static extern uint SizeofResource(IntPtr module,IntPtr resource);
 [DllImport("kernel32.dll",SetLastError=true)]private static extern IntPtr LoadResource(IntPtr module,IntPtr resource);
 [DllImport("kernel32.dll",SetLastError=true)]private static extern IntPtr LockResource(IntPtr resource);
 [DllImport("kernel32.dll",CharSet=CharSet.Unicode,SetLastError=true)]private static extern IntPtr BeginUpdateResource(string file,bool discardExisting);
 [DllImport("kernel32.dll",CharSet=CharSet.Unicode,SetLastError=true)]private static extern bool UpdateResource(IntPtr update,IntPtr type,IntPtr name,ushort language,byte[] data,uint size);
 [DllImport("kernel32.dll",CharSet=CharSet.Unicode,SetLastError=true)]private static extern bool EndUpdateResource(IntPtr update,bool discard);
 private static Exception Error(){return new Win32Exception(Marshal.GetLastWin32Error());}
 private static List<Replacement> Mapping(string path) {
  if(new FileInfo(path).Length>65536)throw new InvalidDataException("Mappa troppo grande.");
  List<Replacement> map;
  using(var stream=File.OpenRead(path))map=(List<Replacement>)new DataContractJsonSerializer(typeof(List<Replacement>),new DataContractJsonSerializerSettings{MaxItemsInObjectGraph=1024}).ReadObject(stream);
  if(map==null||map.Count==0||map.Count>256||map.Select(x=>x.Id).Distinct().Count()!=map.Count)throw new InvalidDataException("Mappa non valida.");
  foreach(var row in map)if(row.Id<1||row.Id>65535||string.IsNullOrEmpty(row.Symbol)||row.Original==null||row.Italian==null||row.Original.Length>4096||row.Italian.Length>4096)throw new InvalidDataException("Stringa non valida.");
  return map;
 }
 private static void RequireResourceOnly(string path) {
  using(var stream=File.OpenRead(path))using(var reader=new BinaryReader(stream)) {
   if(reader.ReadUInt16()!=0x5A4D)throw new InvalidDataException("Immagine PE assente.");
   stream.Position=0x3C;int pe=reader.ReadInt32();
   if(pe<64||pe+64>stream.Length)throw new InvalidDataException("Intestazione PE non valida.");
   stream.Position=pe;if(reader.ReadUInt32()!=0x4550)throw new InvalidDataException("Firma PE non valida.");
   stream.Position=pe+22;if((reader.ReadUInt16()&0x2000)==0)throw new InvalidDataException("Il file non e una DLL.");
   stream.Position=pe+24;ushort magic=reader.ReadUInt16();if(magic!=0x10B&&magic!=0x20B)throw new InvalidDataException("Formato PE non supportato.");
   stream.Position=pe+28;uint codeSize=reader.ReadUInt32();stream.Position=pe+40;uint entry=reader.ReadUInt32();
   if(codeSize!=0||entry!=0)throw new InvalidDataException("Sono ammesse soltanto DLL senza codice e senza entry point.");
  }
 }
 private static Dictionary<int,string[]> ReadBlocks(string file,List<Replacement> map,bool translated) {
  RequireResourceOnly(file);IntPtr module=LoadLibraryEx(Path.GetFullPath(file),IntPtr.Zero,2);
  if(module==IntPtr.Zero)throw Error();
  try {
   var blocks=new Dictionary<int,string[]>();
   foreach(var group in map.GroupBy(x=>x.Id/16+1)) {
    IntPtr resource=FindResourceEx(module,StringType,new IntPtr(group.Key),ItalianLanguage);if(resource==IntPtr.Zero)throw Error();
    uint size=SizeofResource(module,resource);if(size<32||size>131072)throw new InvalidDataException("Blocco risorse non valido.");
    IntPtr address=LockResource(LoadResource(module,resource));if(address==IntPtr.Zero)throw Error();
    byte[] data=new byte[size];Marshal.Copy(address,data,0,data.Length);var strings=new string[16];
    using(var stream=new MemoryStream(data))using(var reader=new BinaryReader(stream)) {
     for(int i=0;i<16;i++){int count=reader.ReadUInt16();byte[] text=reader.ReadBytes(count*2);if(text.Length!=count*2)throw new InvalidDataException("Risorsa troncata.");strings[i]=Encoding.Unicode.GetString(text);}
    }
    foreach(var row in group) {
     string expected=translated?row.Italian:row.Original;
     if(strings[row.Id%16]!=expected)throw new InvalidDataException("Risorsa incompatibile: "+row.Symbol);
    }
    blocks.Add(group.Key,strings);
   }
   return blocks;
  } finally {FreeLibrary(module);}
 }
 private static void Patch(string input,string output,List<Replacement> map) {
  if(string.Equals(Path.GetFullPath(input),Path.GetFullPath(output),StringComparison.OrdinalIgnoreCase))throw new ArgumentException("Usare un file di uscita nuovo.");
  var blocks=ReadBlocks(input,map,false);
  foreach(var row in map)blocks[row.Id/16+1][row.Id%16]=row.Italian;
  File.Copy(input,output,false);IntPtr update=BeginUpdateResource(Path.GetFullPath(output),false);
  if(update==IntPtr.Zero)throw Error();
  try {
   foreach(var block in blocks) {
    byte[] data;
    using(var stream=new MemoryStream())using(var writer=new BinaryWriter(stream)) {
     foreach(string text in block.Value){writer.Write((ushort)text.Length);writer.Write(Encoding.Unicode.GetBytes(text));}
     writer.Flush();data=stream.ToArray();
    }
    if(!UpdateResource(update,StringType,new IntPtr(block.Key),ItalianLanguage,data,(uint)data.Length))throw Error();
   }
   if(!EndUpdateResource(update,false))throw Error();update=IntPtr.Zero;
  } finally {if(update!=IntPtr.Zero)EndUpdateResource(update,true);}
  ReadBlocks(output,map,true);
 }
 private static int Main(string[] args) {
  try {
   if(args.Length==3&&args[0]=="verify"){var map=Mapping(args[2]);ReadBlocks(args[1],map,true);Console.WriteLine("Verificate "+map.Count+" stringhe italiane.");return 0;}
   if(args.Length!=4||args[0]!="patch")throw new ArgumentException("patch originale.dll nuova.dll mappa.json | verify nuova.dll mappa.json");
   var changes=Mapping(args[3]);Patch(args[1],args[2],changes);Console.WriteLine("Localizzate e rilette "+changes.Count+" stringhe italiane.");return 0;
  } catch(Exception ex){Console.Error.WriteLine(ex.GetType().Name+": "+ex.Message);return 1;}
 }
}