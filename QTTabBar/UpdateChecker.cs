// SPDX-License-Identifier: GPL-3.0-or-later
using System;
using System.Diagnostics;

namespace QTTabBarLib {
    internal static class UpdateChecker {
        public static void Check(bool fForce) {
            // Opening a browser is a user action, never a startup/background update check.
            if(!fForce) return;
            try {
                Process.Start(new ProcessStartInfo("https://github.com/mattia-di-chiara-5/QTTabBar-Italiano-Windows10/releases") { UseShellExecute = true });
            } catch(Exception ex) { QTUtility2.MakeErrorLog(ex, "Open releases page"); }
        }
    }
}