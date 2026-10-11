using System;

namespace QTTabBarLib {
    // Request and completion run on the owning UI thread. The executor runs the
    // query elsewhere and posts its completion back to that thread. Keep only
    // one query in flight and discard results superseded by newer input.
    internal sealed class CoalescedQuery<TContext, TResult> : IDisposable {
        private readonly Action<Func<TContext, TResult>, Action<TResult>> execute;
        private readonly Action<TResult> apply;
        private Func<TContext, TResult> latest;
        private long revision;
        private bool running;
        private bool disposed;

        internal CoalescedQuery(Action<Func<TContext, TResult>, Action<TResult>> execute,
                Action<TResult> apply) {
            if(execute == null) throw new ArgumentNullException("execute");
            if(apply == null) throw new ArgumentNullException("apply");
            this.execute = execute;
            this.apply = apply;
        }

        internal void Request(Func<TContext, TResult> query) {
            if(disposed) return;
            if(query == null) throw new ArgumentNullException("query");
            latest = query;
            revision++;
            if(!running) Start();
        }

        private void Start() {
            long requestedRevision = revision;
            running = true;
            execute(latest, result => {
                if(disposed) return;
                running = false;
                if(requestedRevision != revision) {
                    Start();
                    return;
                }
                latest = null;
                apply(result);
            });
        }

        public void Dispose() {
            disposed = true;
            latest = null;
        }
    }
}
