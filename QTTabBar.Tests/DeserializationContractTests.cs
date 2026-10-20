using System.IO;
using System.Reflection;
using System.Runtime.Serialization.Formatters.Binary;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using QTTabBarLib;

namespace QTTabBar.Tests {
    [TestClass]
    public class DeserializationContractTests {
        [TestMethod]
        public void ByteArrayToObject_RejectsUnexpectedRootType() {
            byte[] payload;
            using (MemoryStream stream = new MemoryStream()) {
                new BinaryFormatter().Serialize(stream, "unexpected");
                payload = stream.ToArray();
            }

            MethodInfo deserialize = typeof(BindAction).Assembly
                    .GetType("QTTabBarLib.QTUtility")
                    .GetMethod("ByteArrayToObject", BindingFlags.Public | BindingFlags.Static);

            Assert.IsNull(deserialize.Invoke(null, new object[] { payload }));
        }
    }
}
