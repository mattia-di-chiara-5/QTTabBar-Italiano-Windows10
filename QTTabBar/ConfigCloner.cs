// SPDX-License-Identifier: GPL-3.0-or-later
using System;
using System.Collections;
using System.Drawing;
using System.Reflection;

namespace QTTabBarLib {
    // Only clones live, locally created configuration. Never accepts a serialized object graph.
    internal static class ConfigCloner {
        private static readonly MethodInfo ShallowCopy = typeof(object).GetMethod("MemberwiseClone", BindingFlags.Instance | BindingFlags.NonPublic);

        internal static Config Clone(Config value) {
            return (Config)Copy(value, 0);
        }

        private static object Copy(object value, int depth) {
            if(value == null) return null;
            if(depth > 32) throw new InvalidOperationException("Configuration nesting limit exceeded.");
            Type type = value.GetType();
            if(type.IsValueType || value is string) return value;
            Font font = value as Font;
            if(font != null) return font.Clone();
            Array array = value as Array;
            if(array != null && array.Rank == 1) {
                Array result = (Array)array.Clone();
                for(int i = 0; i < result.Length; i++) result.SetValue(Copy(array.GetValue(i), depth + 1), i);
                return result;
            }
            if(type.IsGenericType && type.GetGenericTypeDefinition() == typeof(System.Collections.Generic.Dictionary<,>)) {
                Type comparerType = typeof(System.Collections.Generic.IEqualityComparer<>).MakeGenericType(type.GetGenericArguments()[0]);
                IDictionary result = (IDictionary)type.GetConstructor(new[] { comparerType }).Invoke(new[] { type.GetProperty("Comparer").GetValue(value, null) });
                foreach(DictionaryEntry entry in (IDictionary)value) result.Add(Copy(entry.Key, depth + 1), Copy(entry.Value, depth + 1));
                return result;
            }
            if(type.IsGenericType && type.GetGenericTypeDefinition() == typeof(System.Collections.Generic.List<>)) {
                IList result = (IList)Activator.CreateInstance(type);
                foreach(object item in (IList)value) result.Add(Copy(item, depth + 1));
                return result;
            }
            if(type != typeof(Config) && type.DeclaringType != typeof(Config) && type != typeof(XmlSerializableFont))
                throw new NotSupportedException("Unsupported configuration member: " + type.FullName);
            object clone = ShallowCopy.Invoke(value, null);
            foreach(PropertyInfo property in type.GetProperties(BindingFlags.Instance | BindingFlags.Public)) {
                if(property.CanRead && property.CanWrite && property.GetIndexParameters().Length == 0)
                    property.SetValue(clone, Copy(property.GetValue(value, null), depth + 1), null);
            }
            return clone;
        }
    }
}
