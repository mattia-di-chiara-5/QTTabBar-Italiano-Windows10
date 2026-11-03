// SPDX-License-Identifier: GPL-3.0-or-later
using System;
using System.ServiceModel;

namespace QTTabBarLib {
    internal static class IpcTransport {
        internal static NetNamedPipeBinding CreateBinding() {
            return new NetNamedPipeBinding(NetNamedPipeSecurityMode.Transport) {
                OpenTimeout = TimeSpan.FromSeconds(2), SendTimeout = TimeSpan.FromSeconds(2),
                CloseTimeout = TimeSpan.FromSeconds(1), ReceiveTimeout = TimeSpan.FromMinutes(10),
                MaxBufferSize = IpcCommand.MaxBytes, MaxReceivedMessageSize = IpcCommand.MaxBytes,
                ReaderQuotas = { MaxArrayLength = IpcCommand.MaxBytes, MaxDepth = 16, MaxStringContentLength = 32768, MaxNameTableCharCount = 16384, MaxBytesPerRead = 4096 }
            };
        }
    }
}
