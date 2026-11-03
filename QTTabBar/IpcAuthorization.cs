// SPDX-License-Identifier: GPL-3.0-or-later
using System.Security.Principal;
using System.ServiceModel;

namespace QTTabBarLib {
    internal sealed class IpcAuthorization : ServiceAuthorizationManager {
        private readonly SecurityIdentifier owner = WindowsIdentity.GetCurrent().User;
        protected override bool CheckAccessCore(OperationContext context) {
            ServiceSecurityContext security = context.ServiceSecurityContext;
            return security != null && !security.IsAnonymous && security.WindowsIdentity != null
                && owner != null && owner.Equals(security.WindowsIdentity.User);
        }
    }
}
