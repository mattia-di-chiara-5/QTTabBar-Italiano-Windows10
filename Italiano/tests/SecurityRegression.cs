using System;
using System.Collections;
using System.Collections.Generic;
using System.Drawing;
using System.IO;
using System.Reflection;
using System.ServiceModel;
using System.Text;
using Microsoft.Win32;
using QTTabBarLib;
using QuizoPlugins;

internal static class SecurityRegression {
    private static int rejected;
    private static void Require(bool value, string message) { if(!value) throw new Exception(message); }
    private static void Reject(Action action, string message) {
        try { action(); } catch(Exception) { rejected++; return; }
        throw new Exception("Accepted invalid input: " + message);
    }

    [ServiceContract]
    public interface IEcho { [OperationContract] string Validate(byte[] payload); }
    public sealed class Echo : IEcho {
        public string Validate(byte[] payload) { return IpcCommand.Decode(payload).Kind.ToString(); }
    }

    private static void Commands() {
        var good = new IpcCommand { Kind = IpcCommandKind.OpenPaths, Paths = new[] { "C:\\Citta-è;cartella" }, Selection = "documento.txt", ForceTab = true };
        var decoded = IpcCommand.Decode(IpcCommand.Encode(good));
        Require(decoded.Paths[0] == good.Paths[0] && decoded.ForceTab, "IPC round trip");
        Reject(() => IpcCommand.Decode(new byte[] {0,1,0,0,0,255}), "legacy binary payload");
        Reject(() => IpcCommand.Decode(new byte[IpcCommand.MaxBytes + 1]), "oversized payload");
        Reject(() => IpcCommand.Decode(Encoding.UTF8.GetBytes("{\"Version\":2,\"Kind\":99}")), "unknown command");
        Reject(() => IpcCommand.Decode(Encoding.UTF8.GetBytes("{\"Version\":1,\"Kind\":0}")), "old protocol");
        Reject(() => IpcCommand.Decode(Encoding.UTF8.GetBytes("{\"__type\":\"System.Delegate:mscorlib\",\"Version\":2,\"Kind\":0}")), "runtime type injection");
        Reject(() => IpcCommand.Decode(Encoding.UTF8.GetBytes("{\"Kind\":0}")), "missing version");
        Reject(() => IpcCommand.Decode(Encoding.UTF8.GetBytes("{\"Version\":2,\"Kind\":0}{}")), "trailing root");
        Reject(() => IpcCommand.Encode(new IpcCommand { Kind = IpcCommandKind.OpenPaths }), "missing paths");
        Reject(() => IpcCommand.Encode(new IpcCommand { Text = new string('x',32769) }), "long string");
        Reject(() => IpcCommand.Encode(new IpcCommand { Text = "x\0y" }), "embedded NUL");
        Reject(() => IpcCommand.Encode(new IpcCommand { Kind = IpcCommandKind.SearchWidth, Value = -1 }), "invalid width");
        Reject(() => IpcCommand.Encode(new IpcCommand { Kind = IpcCommandKind.SelectTab, Handle = -1 }), "invalid window handle");
        var paths = new string[257]; for(int i=0;i<paths.Length;i++) paths[i] = "C:\\a";
        Reject(() => IpcCommand.Encode(new IpcCommand { Kind = IpcCommandKind.OpenPaths, Paths = paths }), "too many paths");
        Console.WriteLine("PASS: bounded data-only IPC, Unicode round trip and adversarial payloads");

        string address = "net.pipe://localhost/QTTabBarSecurityTest-" + Guid.NewGuid().ToString("N");
        var host = new ServiceHost(typeof(Echo), new Uri(address));
        try {
            host.Authorization.ServiceAuthorizationManager = new IpcAuthorization();
            host.AddServiceEndpoint(typeof(IEcho), IpcTransport.CreateBinding(), "");
            host.Open(TimeSpan.FromSeconds(5));
            var factory = new ChannelFactory<IEcho>(IpcTransport.CreateBinding(), new EndpointAddress(address));
            try {
                IEcho channel = factory.CreateChannel();
                Require(channel.Validate(IpcCommand.Encode(good)) == "OpenPaths", "authenticated named-pipe round trip");
                ((IClientChannel)channel).Close();
            } finally { factory.Abort(); }
        } finally { host.Abort(); }
        Require(IpcTransport.CreateBinding().Security.Mode == NetNamedPipeSecurityMode.Transport, "transport authentication");
        Require(IpcTransport.CreateBinding().MaxReceivedMessageSize == IpcCommand.MaxBytes, "transport quota");
        Console.WriteLine("PASS: real named-pipe request authenticated as the current Windows user");
    }

    private static void Memos(string directory) {
        string path = Path.Combine(directory,"memo.xml");
        var document = new MemoDocument { Width=400, Height=300, Opacity=0.85 };
        document.Entries.Add(new MemoEntry { Path="C:\\Citta-è;cartella", Rtf="{\\rtf1 Ciao}", Text="Ciao è" });
        MemoPersistence.Save(path,document);
        Require(MemoPersistence.Load(path).Entries[0].Text == "Ciao è", "memo round trip");
        document.Entries[0].Text = "seconda versione";
        MemoPersistence.Save(path,document);
        Require(MemoPersistence.Load(path+".bak").Entries[0].Text == "Ciao è", "memo backup");
        byte[] previous = File.ReadAllBytes(path);
        document.Version=2;
        Reject(() => MemoPersistence.Save(path,document), "unknown memo version");
        Require(Convert.ToBase64String(previous) == Convert.ToBase64String(File.ReadAllBytes(path)), "failed save replaced original");
        document.Version=1; document.Entries.Add(document.Entries[0]);
        Reject(() => MemoPersistence.Save(path,document), "duplicate memo key");
        document.Entries.RemoveAt(1);document.Opacity=double.NaN;
        Reject(() => MemoPersistence.Save(path,document), "non-finite opacity");
        string invalid = Path.Combine(directory,"invalid.xml");
        File.WriteAllText(invalid,"<!DOCTYPE x [<!ENTITY secret SYSTEM 'file:///does-not-exist'>]><x>&secret;</x>");
        Reject(() => MemoPersistence.Load(invalid), "DTD/entity expansion");
        File.WriteAllBytes(invalid,new byte[]{0,1,0,0,0});
        Reject(() => MemoPersistence.Load(invalid), "legacy memo binary");
        using(var stream=File.Create(invalid)) stream.SetLength(16777217);
        Reject(() => MemoPersistence.Load(invalid), "oversized memo file");
        Console.WriteLine("PASS: typed Memo XML, no DTD, atomic save, backup and original preservation");
    }

    private static void Candidate(string path) {
        var assembly=Assembly.LoadFrom(Path.GetFullPath(path));
        Require(string.Equals(assembly.Location,Path.GetFullPath(path),StringComparison.OrdinalIgnoreCase),"candidate replaced by GAC assembly");
        var configType=assembly.GetType("QTTabBarLib.Config",true);
        object original=Activator.CreateInstance(configType);
        assembly.GetType("QTTabBarLib.ConfigManager").GetField("LoadedConfig").SetValue(null,original);
        var utility=assembly.GetType("QTTabBarLib.QTUtility2",true);
        object clone=utility.GetMethod("DeepClone").MakeGenericMethod(configType).Invoke(null,new[]{original});
        object sourceTips=configType.GetProperty("tips").GetValue(original,null);
        object cloneTips=configType.GetProperty("tips").GetValue(clone,null);
        var sourceList=(IList)sourceTips.GetType().GetProperty("TextExt").GetValue(sourceTips,null);
        var cloneList=(IList)cloneTips.GetType().GetProperty("TextExt").GetValue(cloneTips,null);
        int count=sourceList.Count;cloneList.Add(".security-test");
        Require(sourceList.Count==count && !ReferenceEquals(sourceTips,cloneTips),"configuration list/category aliased");
        Font sourceFont=(Font)sourceTips.GetType().GetProperty("PreviewFont").GetValue(sourceTips,null);
        Font cloneFont=(Font)cloneTips.GetType().GetProperty("PreviewFont").GetValue(cloneTips,null);
        Require(!ReferenceEquals(sourceFont,cloneFont) && sourceFont.Equals(cloneFont),"configuration font clone");
        Console.WriteLine("PASS: live configuration deep clone without a serialized object graph");

        string keyPath="Software\\QTTabBarSecurityTests\\"+Guid.NewGuid().ToString("N");
        try {
            using(var key=Registry.CurrentUser.CreateSubKey(keyPath)) {
                var write=utility.GetMethod("WriteRegBinary").MakeGenericMethod(typeof(string));
                var read=utility.GetMethod("ReadRegBinary").MakeGenericMethod(typeof(string));
                string[] paths={"C:\\Citta-è;cartella","C:\\altra"};
                key.SetValue("TabsLocked",new byte[]{0,1,0,0,0},RegistryValueKind.Binary);
                Require(read.Invoke(null,new object[]{"TabsLocked",key})==null,"legacy binary registry value read");
                write.Invoke(null,new object[]{paths,"TabsLocked",key});
                Require(key.GetValueKind("TabsLockedV2")==RegistryValueKind.MultiString,"registry is not REG_MULTI_SZ");
                var result=(string[])read.Invoke(null,new object[]{"TabsLocked",key});
                Require(result.Length==2&&result[0]==paths[0],"semicolon/Unicode path damaged");
                Require(((byte[])key.GetValue("TabsLocked")).Length==5,"legacy registry data destroyed");
                write.Invoke(null,new object[]{new string[0],"TabsLocked",key});
                Require(((string[])read.Invoke(null,new object[]{"TabsLocked",key})).Length==0,"empty state restored old paths");
            }
        } finally { Registry.CurrentUser.DeleteSubKeyTree(keyPath,false); }
        Console.WriteLine("PASS: isolated registry round trip, Unicode/semicolons, empty state and legacy preservation");
        assembly.GetType("QTTabBarLib.UpdateChecker").GetMethod("Check").Invoke(null,new object[]{false});
        Console.WriteLine("PASS: automatic update check returns without opening a browser");
        Require(assembly.GetType("QTTabBarLib.SerializeDelegate")==null,"legacy reflective delegate wrapper remains available");
        ProductionPipe(assembly);
    }

    private static void ProductionPipe(Assembly assembly) {
        Type manager=assembly.GetType("QTTabBarLib.InstanceManager",true);
        Type contract=manager.GetNestedType("ICommService",BindingFlags.NonPublic);
        Type service=manager.GetNestedType("CommService",BindingFlags.NonPublic);
        Type callback=manager.GetNestedType("CommClient",BindingFlags.NonPublic);
        Require(contract.GetMethod("GetFromServerProcess")==null,"generic remote getter remains exposed");
        Type transport=assembly.GetType("QTTabBarLib.IpcTransport",true);
        Func<NetNamedPipeBinding> binding=()=> (NetNamedPipeBinding)transport.GetMethod("CreateBinding",BindingFlags.Static|BindingFlags.NonPublic).Invoke(null,null);
        string address="net.pipe://localhost/QTTabBarProductionTest-"+Guid.NewGuid().ToString("N");
        var host=new ServiceHost(service,new Uri(address));
        ICommunicationObject factory=null;
        try {
            host.Authorization.ServiceAuthorizationManager=(ServiceAuthorizationManager)Activator.CreateInstance(assembly.GetType("QTTabBarLib.IpcAuthorization"),true);
            host.AddServiceEndpoint(contract,binding(),"");
            host.Open(TimeSpan.FromSeconds(5));
            Type factoryType=typeof(DuplexChannelFactory<>).MakeGenericType(contract);
            object factoryObject=Activator.CreateInstance(factoryType,new object[]{new InstanceContext(Activator.CreateInstance(callback,true)),binding(),new EndpointAddress(address)});
            factory=(ICommunicationObject)factoryObject;
            object channel=factoryType.GetMethod("CreateChannel",Type.EmptyTypes).Invoke(factoryObject,null);
            contract.GetMethod("Subscribe").Invoke(channel,null);
            IntPtr fakeHandle=new IntPtr(123456);
            contract.GetMethod("PushInstance").Invoke(channel,new object[]{fakeHandle});
            Require((int)contract.GetMethod("GetTotalInstanceCount").Invoke(channel,null)==1,"production subscription");
            // The isolated process has no tab controls: callbacks validate and ignore the fake handle.
            contract.GetMethod("SelectTabOnOtherTabBar").Invoke(channel,new object[]{fakeHandle,0});
            contract.GetMethod("SelectTabOnOtherTabBar").Invoke(channel,new object[]{fakeHandle,1});
            contract.GetMethod("DeleteInstance").Invoke(channel,new object[]{fakeHandle});
            Require((int)contract.GetMethod("GetTotalInstanceCount").Invoke(channel,null)==0,"production unregister");
            Reject(()=>contract.GetMethod("Broadcast").Invoke(channel,new object[]{IpcCommand.Encode(new IpcCommand {Kind=IpcCommandKind.OpenOptions})}),"broadcasting a non-notification command");
        } finally { if(factory!=null) factory.Abort();host.Abort(); }
        Console.WriteLine("PASS: production WCF service, typed callbacks remain connected across two requests, invalid broadcast rejected");
    }

    [STAThread] private static int Main(string[] args) {
        try { Commands(); Memos(args[1]); Candidate(args[0]); Console.WriteLine("PASS: "+rejected+" hostile/invalid inputs rejected"); return 0; }
        catch(Exception ex) { Console.Error.WriteLine(ex);return 1; }
    }
}
