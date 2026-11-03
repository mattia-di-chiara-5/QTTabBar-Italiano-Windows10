// SPDX-License-Identifier: GPL-3.0-or-later
using System;
using System.Collections.Generic;
using System.IO;
using System.Runtime.Serialization;
using System.Xml;

namespace QuizoPlugins {
    [DataContract]
    internal sealed class MemoDocument {
        [DataMember(IsRequired = true)] internal int Version = 1;
        [DataMember] internal int X, Y, Width, Height;
        [DataMember] internal double Opacity;
        [DataMember] internal List<MemoEntry> Entries = new List<MemoEntry>();
        internal void Validate() {
            if(Version != 1 || Entries == null || Entries.Count > 2048 || double.IsNaN(Opacity) || Opacity < 0 || Opacity > 1
                || Width < 100 || Height < 100 || Width > 16384 || Height > 16384 || Math.Abs((long)X) > 100000 || Math.Abs((long)Y) > 100000)
                throw new InvalidDataException("Invalid memo document.");
            var seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            foreach(MemoEntry entry in Entries) {
                if(entry == null || string.IsNullOrEmpty(entry.Path) || entry.Path.Length > 32768 || entry.Path.IndexOf('\0') >= 0 || !seen.Add(entry.Path)
                    || entry.Rtf == null || entry.Text == null || entry.Rtf.Length > 2097152 || entry.Text.Length > 2097152)
                    throw new InvalidDataException("Invalid memo entry.");
            }
        }
    }
    [DataContract]
    internal sealed class MemoEntry {
        [DataMember(IsRequired = true)] internal string Path;
        [DataMember(IsRequired = true)] internal string Rtf;
        [DataMember(IsRequired = true)] internal string Text;
    }
    internal static class MemoPersistence {
        private const int MaxBytes = 16777216;
        private sealed class BoundedBuffer : MemoryStream {
            public override void Write(byte[] buffer, int offset, int count) {
                if(count < 0 || Position + count > MaxBytes) throw new InvalidDataException("Memo document too large.");
                base.Write(buffer, offset, count);
            }
            public override void WriteByte(byte value) {
                if(Position >= MaxBytes) throw new InvalidDataException("Memo document too large.");
                base.WriteByte(value);
            }
        }
        private static DataContractSerializer Serializer() {
            return new DataContractSerializer(typeof(MemoDocument), new DataContractSerializerSettings { MaxItemsInObjectGraph = 16384 });
        }
        internal static MemoDocument Load(string path) {
            using(var stream = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.Read)) {
                if(stream.Length > MaxBytes) throw new InvalidDataException("Memo document too large.");
                var settings = new XmlReaderSettings { DtdProcessing = DtdProcessing.Prohibit, XmlResolver = null, MaxCharactersInDocument = MaxBytes };
                using(var reader = XmlReader.Create(stream, settings)) {
                    var document = (MemoDocument)Serializer().ReadObject(reader);
                    if(document == null) throw new InvalidDataException("Missing memo document.");
                    document.Validate();
                    while(reader.Read()) if(reader.NodeType != XmlNodeType.Whitespace) throw new InvalidDataException("Trailing memo data.");
                    return document;
                }
            }
        }
        internal static void Save(string path, MemoDocument document) {
            document.Validate();
            using(var buffer = new BoundedBuffer()) {
                Serializer().WriteObject(buffer, document);
                if(buffer.Length > MaxBytes) throw new InvalidDataException("Memo document too large.");
                Directory.CreateDirectory(Path.GetDirectoryName(path));
                string temporary = path + "." + Guid.NewGuid().ToString("N") + ".tmp";
                try {
                    File.WriteAllBytes(temporary, buffer.ToArray());
                    if(File.Exists(path)) File.Replace(temporary, path, path + ".bak");
                    else File.Move(temporary, path);
                } finally { if(File.Exists(temporary)) File.Delete(temporary); }
            }
        }
    }
}
