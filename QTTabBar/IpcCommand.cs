// SPDX-License-Identifier: GPL-3.0-or-later
using System;
using System.IO;
using System.Runtime.Serialization;
using System.Runtime.Serialization.Json;
using System.Xml;

namespace QTTabBarLib {
    [DataContract]
    internal enum IpcCommandKind {
        [EnumMember] ReloadApps,
        [EnumMember] ReloadConfig,
        [EnumMember] ReloadGroups,
        [EnumMember] RefreshButtons,
        [EnumMember] SearchWidth,
        [EnumMember] OpenOptions,
        [EnumMember] OpenPaths,
        [EnumMember] OpenGroup,
        [EnumMember] PluginOptions,
        [EnumMember] SelectTab
    }

    // Closed, data-only protocol. No runtime type names, methods, delegates or serialized PIDLs.
    [DataContract]
    internal sealed class IpcCommand {
        internal const int MaxBytes = 1048576;
        [DataMember(IsRequired = true)] internal int Version = 2;
        [DataMember(IsRequired = true)] internal IpcCommandKind Kind;
        [DataMember] internal string[] Paths;
        [DataMember] internal string Text;
        [DataMember] internal string Selection;
        [DataMember] internal int Value;
        [DataMember] internal long Handle;
        [DataMember] internal bool ForceTab;
        [DataMember] internal bool Restore;
        [DataMember] internal bool Pulse;
        [DataMember] internal bool WaitForSelection;

        internal void Validate() {
            if(Version != 2 || !Enum.IsDefined(typeof(IpcCommandKind), Kind)) throw new InvalidDataException("Unsupported IPC command.");
            CheckString(Text); CheckString(Selection);
            long length = (Text == null ? 0 : Text.Length) + (Selection == null ? 0 : Selection.Length);
            if(Paths != null) {
                if(Paths.Length > 256) throw new InvalidDataException("Too many paths.");
                foreach(string path in Paths) { CheckString(path); if(string.IsNullOrWhiteSpace(path)) throw new InvalidDataException("Empty path."); length += path.Length; }
            }
            if(length > 131072) throw new InvalidDataException("Command too large.");
            if(Kind == IpcCommandKind.OpenPaths && (Paths == null || Paths.Length == 0)) throw new InvalidDataException("Missing paths.");
            if((Kind == IpcCommandKind.OpenGroup || Kind == IpcCommandKind.PluginOptions) && string.IsNullOrWhiteSpace(Text)) throw new InvalidDataException("Missing identifier.");
            if(Kind == IpcCommandKind.SearchWidth && (Value < 16 || Value > 4096)) throw new InvalidDataException("Invalid width.");
            if(Kind == IpcCommandKind.SelectTab && (Value < 0 || Value > 4096 || Handle <= 0 || (IntPtr.Size == 4 && Handle > uint.MaxValue))) throw new InvalidDataException("Invalid tab reference.");
        }

        private static void CheckString(string text) {
            if(text != null && (text.Length > 32768 || text.IndexOf('\0') >= 0)) throw new InvalidDataException("Invalid string.");
        }

        internal static byte[] Encode(IpcCommand command) {
            if(command == null) throw new ArgumentNullException("command");
            command.Validate();
            using(var stream = new MemoryStream()) {
                Serializer().WriteObject(stream, command);
                if(stream.Length > MaxBytes) throw new InvalidDataException("IPC payload too large.");
                return stream.ToArray();
            }
        }

        internal static IpcCommand Decode(byte[] bytes) {
            if(bytes == null || bytes.Length == 0 || bytes.Length > MaxBytes) throw new InvalidDataException("Invalid IPC payload length.");
            ValidateFrame(bytes);
            var quotas = new XmlDictionaryReaderQuotas { MaxDepth = 16, MaxArrayLength = 65536, MaxStringContentLength = 32768, MaxBytesPerRead = 4096, MaxNameTableCharCount = 16384 };
            using(var reader = JsonReaderWriterFactory.CreateJsonReader(bytes, quotas)) {
                var command = (IpcCommand)Serializer().ReadObject(reader);
                if(command == null) throw new InvalidDataException("Missing IPC command.");
                command.Validate();
                // Reject a second root value or non-whitespace trailing data.
                while(reader.Read()) if(reader.NodeType != XmlNodeType.Whitespace && reader.NodeType != XmlNodeType.SignificantWhitespace) throw new InvalidDataException("Trailing IPC data.");
                return command;
            }
        }

        private static void ValidateFrame(byte[] bytes) {
            // The framework JSON reader stops after its first root and can ignore a second one.
            // Check framing independently before handing any data to it.
            new System.Text.UTF8Encoding(false, true).GetString(bytes);
            int first = 0;
            while(first < bytes.Length && IsWhitespace(bytes[first])) first++;
            if(first == bytes.Length || bytes[first] != (byte)'{') throw new InvalidDataException("Expected a JSON command object.");
            int depth = 0; bool inString = false, escaped = false, ended = false;
            for(int i = first; i < bytes.Length; i++) {
                byte value = bytes[i];
                if(ended) { if(!IsWhitespace(value)) throw new InvalidDataException("Trailing IPC data."); continue; }
                if(inString) {
                    if(escaped) escaped = false;
                    else if(value == (byte)'\\') escaped = true;
                    else if(value == (byte)'"') inString = false;
                } else if(value == (byte)'"') inString = true;
                else if(value == (byte)'{' || value == (byte)'[') {
                    if(++depth > 16) throw new InvalidDataException("IPC nesting limit exceeded.");
                } else if(value == (byte)'}' || value == (byte)']') {
                    if(--depth < 0) throw new InvalidDataException("Invalid JSON framing.");
                    if(depth == 0) ended = true;
                }
            }
            if(!ended || inString) throw new InvalidDataException("Incomplete IPC command.");
        }

        private static bool IsWhitespace(byte value) { return value == 32 || value == 9 || value == 10 || value == 13; }

        private static DataContractJsonSerializer Serializer() {
            return new DataContractJsonSerializer(typeof(IpcCommand), new DataContractJsonSerializerSettings { MaxItemsInObjectGraph = 4096 });
        }
    }
}
