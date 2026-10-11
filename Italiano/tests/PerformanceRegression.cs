using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Reflection;
using System.Threading;
using System.Windows.Forms;
using QTTabBarLib;

internal static class PerformanceRegression {
    private static int workerThread;
    private static ApartmentState workerApartment;

    public static int SlowProvider(object unused) {
        workerThread = Thread.CurrentThread.ManagedThreadId;
        workerApartment = Thread.CurrentThread.GetApartmentState();
        Thread.Sleep(250);
        return 42;
    }
    private static void Require(bool value, string message) {
        if(!value) throw new Exception(message);
    }

    [STAThread]
    private static int Main(string[] args) {
        try {
            // The launcher enables DEVPATH only for this test process so the
            // installed GAC assembly cannot replace the candidate.
            var assembly = Assembly.Load(System.IO.File.ReadAllBytes(args[0]));
            Require(string.IsNullOrEmpty(assembly.Location) ||
                string.Equals(assembly.Location, System.IO.Path.GetFullPath(args[0]), StringComparison.OrdinalIgnoreCase),
                "Test loaded a different assembly: " + assembly.Location);
            var pending = new Queue<Action>();
            var applied = new List<int>();
            var queue = new CoalescedQuery<object, int>(
                (query, complete) => pending.Enqueue(() => complete(query(null))),
                result => applied.Add(result));
            for(int i = 0; i < 10000; i++) {
                int captured = i;
                queue.Request(context => captured);
            }
            Require(pending.Count == 1, "Mouse burst created an unbounded work queue");
            pending.Dequeue()();
            Require(applied.Count == 0 && pending.Count == 1, "Superseded result was applied");
            pending.Dequeue()();
            Require(applied.Count == 1 && applied[0] == 9999, "Latest mouse position was lost");
            queue.Request(context => 10000);
            queue.Dispose();
            pending.Dequeue()();
            Require(applied.Count == 1, "Result applied after view disposal");
            Console.WriteLine("PASS: 10,000 hover requests collapse to two queries; stale/disposed results are discarded");

            int uiThread = Thread.CurrentThread.ManagedThreadId;
            int callbackThread = -1, resultValue = -1;
            workerThread = -1;
            workerApartment = ApartmentState.Unknown;
            var sync = new WindowsFormsSynchronizationContext();
            var manager = assembly.GetType("QTTabBarLib.AutomationManager", true);
            var factoryType = assembly.GetType("QTTabBarLib.AutomationElementFactory", true);
            var queryDefinition = manager.GetNestedType("Query`1", BindingFlags.Public | BindingFlags.NonPublic);
            Require(queryDefinition != null, "Automation Query delegate missing");
            Require(manager.GetMethod("BeginQuery") != null, "Async API missing from " + assembly.Location);
            var queryType = queryDefinition.MakeGenericType(typeof(int));
            var queryDelegate = Delegate.CreateDelegate(queryType, typeof(PerformanceRegression).GetMethod("SlowProvider"));
            Action<int> providerCompleted = result => {
                callbackThread = Thread.CurrentThread.ManagedThreadId;
                resultValue = result;
            };
            var watch = Stopwatch.StartNew();
            manager.GetMethod("BeginQuery").MakeGenericMethod(typeof(int))
                .Invoke(null, new object[] { queryDelegate, sync, providerCompleted });
            long returnedMs = watch.ElapsedMilliseconds;
            int uiTicks = 0;
            while(resultValue == -1 && watch.ElapsedMilliseconds < 5000) {
                Application.DoEvents();
                Thread.Sleep(5);
                uiTicks++;
            }
            Require(returnedMs < 150, "Provider blocked the calling UI thread");
            Require(resultValue == 42 && uiTicks >= 5, "Slow provider failure: result=" + resultValue + ", ticks=" + uiTicks + ", worker=" + workerThread + ", returnedMs=" + returnedMs);
            Require(workerThread != uiThread && workerApartment == ApartmentState.MTA, "UIA client did not run on its MTA worker");
            Require(callbackThread == uiThread, "Cache completion did not return to its owning UI thread");
            Console.WriteLine("PASS: slow provider (250 ms), request returned in {0} ms, UI pumped {1} times; MTA worker/STA completion", returnedMs, uiTicks);

            var shellMethods = assembly.GetType("QTTabBarLib.Interop.ShellMethods", true);
            var makeTip = shellMethods.GetMethod("TryMakeSubDirTipPath", BindingFlags.Public | BindingFlags.Static);
            makeTip.Invoke(null, new object[] { "" }); // Exclude class/JIT initialization.
            var path = new object[] { @"\\192.0.2.1\unreachable\folder" };
            watch.Restart();
            bool accepted = (bool)makeTip.Invoke(null, path);
            Require(!accepted && watch.ElapsedMilliseconds < 150, "Remote hover path performed blocking network I/O");
            Console.WriteLine("PASS: unreachable UNC hover rejected before network access ({0} ms)", watch.ElapsedMilliseconds);
            return 0;
        }
        catch(Exception exception) {
            Console.Error.WriteLine(exception);
            return 1;
        }
    }
}
