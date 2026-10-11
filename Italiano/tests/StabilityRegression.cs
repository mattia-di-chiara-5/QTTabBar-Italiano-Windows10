using System;
using System.Collections;
using System.Collections.Generic;
using System.Drawing;
using System.IO;
using System.Reflection;
using System.Resources;
using System.Threading;
using System.Windows.Forms;


internal static class StabilityRegression {
    private static void Require(bool value, string message) {
        if (!value) throw new Exception(message);
    }

    [STAThread]
    private static int Main(string[] args) {
        try {
            var assembly = Assembly.LoadFrom(Path.GetFullPath(args[0]));
            var storeType = assembly.GetType("QTTabBarLib.ThreadImageListStore", true);
            var store = Activator.CreateInstance(storeType, BindingFlags.Instance | BindingFlags.NonPublic,
                null, new object[] { new Func<ImageList>(() => new ImageList()) }, null);
            var current = storeType.GetProperty("Current", BindingFlags.Instance | BindingFlags.NonPublic);
            var lists = new ImageList[4];
            var failures = new Exception[4];
            var start = new ManualResetEvent(false);
            var threads = new Thread[4];
            for (int i = 0; i < threads.Length; i++) {
                int worker = i;
                threads[i] = new Thread(() => {
                    try {
                        start.WaitOne();
                        var list = (ImageList)current.GetValue(store, null);
                        lists[worker] = list;
                        Require(ReferenceEquals(list, current.GetValue(store, null)), "List changed on same thread");
                        using (var bitmap = new Bitmap(16, 16)) {
                            for (int j = 0; j < 500; j++) {
                                string key = worker + ":" + j;
                                list.Images.Add(key, bitmap);
                                Require(list.Images.ContainsKey(key), "Missing icon");
                                using (var icon = list.Images[key]) Require(icon.Width == 16, "Invalid image");
                                list.Images.Clear();
                            }
                        }
                    } catch (Exception ex) { failures[worker] = ex; }
                });
                threads[i].SetApartmentState(ApartmentState.STA);
                threads[i].Start();
            }
            start.Set();
            foreach (var thread in threads) Require(thread.Join(30000), "Icon stress timeout");
            foreach (var failure in failures) if (failure != null) throw failure;
            for (int i = 0; i < lists.Length; i++)
                for (int j = i + 1; j < lists.Length; j++)
                    Require(!ReferenceEquals(lists[i], lists[j]), "ImageList shared across STA threads");
            Console.WriteLine("PASS: 4 STA threads, 2,000 icon add/lookup/read/clear cycles");

            var configType = assembly.GetType("QTTabBarLib.Config", true);
            var manager = assembly.GetType("QTTabBarLib.ConfigManager", true);
            manager.GetField("LoadedConfig").SetValue(null, Activator.CreateInstance(configType, true));
            var utility = assembly.GetType("QTTabBarLib.QTUtility", true);
            var culture = utility.GetMethod("GetBuiltInLanguageCulture", BindingFlags.Static | BindingFlags.NonPublic)
                .Invoke(null, new object[] { 8 });
            Require(culture.ToString() == "it-IT", "Italian culture missing");
            var resources = new ResourceManager("Resources_String_it_IT", assembly);
            Require(!string.IsNullOrEmpty(resources.GetString("TabBar_Menu")), "Italian resources missing");
            Console.WriteLine("PASS: built-in Italian resources and culture");
            // The test runs without NuGet DLLs next to QTTabBar.dll, as in the GAC.
            var detectorAssembly = Assembly.Load("UtfUnknown, Version=2.0.0.0, Culture=neutral, PublicKeyToken=90217ce7a23260d4");
            Require(string.IsNullOrEmpty(detectorAssembly.Location), "Encoding detector did not load from embedded resources");
            var detector = detectorAssembly.GetType("UtfUnknown.CharsetDetector", true);
            var detect = detector.GetMethod("DetectFromBytes", new Type[] { typeof(byte[]) });
            Require(detect != null, "Encoding detector API missing");
            var detected = detect.Invoke(null, new object[] { System.Text.Encoding.UTF8.GetBytes("Citta italiana: àèìòù. Ripetizione àèìòù.") });
            Require(detected != null, "Encoding detection failed");
            Console.WriteLine("PASS: embedded encoding detector and its dependencies load without sidecar DLLs");

            var controlType = assembly.GetType("QTTabBarLib.QTabControl", true);
            string errorLog = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "QTTabBar\\QTTabBarException.log");
            long errorsBefore = File.Exists(errorLog) ? new FileInfo(errorLog).Length : 0;
            using (var control = (Control)Activator.CreateInstance(controlType, true)) {
                control.Size = new Size(600, 40);
                controlType.GetMethod("RefreshOptions").Invoke(control, new object[] { true });
                var itemType = assembly.GetType("QTTabBarLib.QTabItem", true);
                var item = Activator.CreateInstance(itemType, BindingFlags.Public | BindingFlags.Instance,
                    null, new object[] { "Cartella di prova", Path.GetTempPath(), control }, null);
                var pages = controlType.GetProperty("TabPages").GetValue(control, null);
                pages.GetType().GetMethod("Add", BindingFlags.Public | BindingFlags.Instance | BindingFlags.DeclaredOnly)
                    .Invoke(pages, new object[] { item });
                var draw = controlType.GetMethod("DrawTab", BindingFlags.Instance | BindingFlags.NonPublic);
                var active = controlType.GetField("brshActive", BindingFlags.Instance | BindingFlags.NonPublic);
                var inactive = controlType.GetField("brshInactv", BindingFlags.Instance | BindingFlags.NonPublic);
                controlType.GetField("fDrawShadow", BindingFlags.Instance | BindingFlags.NonPublic).SetValue(control, false);
                using (var bitmap = new Bitmap(600, 40))
                using (var graphics = Graphics.FromImage(bitmap)) {
                    object oldActive = null, oldInactive = null;
                    for (int i = 0; i < 2000; i++) {
                        draw.Invoke(control, new object[] { graphics, new Rectangle(0, 0, 180, 32), 0, null, false });
                        object a = active.GetValue(control), b = inactive.GetValue(control);
                        Require(a != null && b != null, "Brush not created");
                        if (i > 0) Require(ReferenceEquals(a, oldActive) && ReferenceEquals(b, oldInactive), "Brush recreated during repaint");
                        oldActive = a; oldInactive = b;
                    }
                }
            }
            Require((File.Exists(errorLog) ? new FileInfo(errorLog).Length : 0) == errorsBefore, "Tab rendering logged an exception");
            Console.WriteLine("PASS: 2,000 real tab repaints reuse the same brushes");
            return 0;
        } catch (Exception ex) {
            Console.Error.WriteLine(ex);
            return 1;
        }
    }
}
