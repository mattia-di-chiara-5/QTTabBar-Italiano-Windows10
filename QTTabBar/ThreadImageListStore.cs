using System;
using System.Threading;
using System.Windows.Forms;

namespace QTTabBarLib {
    // ImageList and its native handle belong to one UI thread. In particular,
    // ImageCollection.IndexOfKey mutates a cached index even when only reading.
    internal sealed class ThreadImageListStore {
        private readonly ThreadLocal<ImageList> images;

        internal ThreadImageListStore(Func<ImageList> factory) {
            if (factory == null) throw new ArgumentNullException("factory");
            // Do not track other threads' values: their finalizable ImageLists can
            // be collected when those threads and their controls are released.
            images = new ThreadLocal<ImageList>(factory);
        }

        internal ImageList Current { get { return images.Value; } }
    }
}
