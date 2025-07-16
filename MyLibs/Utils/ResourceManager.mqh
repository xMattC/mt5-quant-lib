//+------------------------------------------------------------------+
//|                                             ResourceManager.mqh  |
//|                    Central manager for indicator handle cleanup  |
//|                                                                  |
//|                                  2025 xMattC (github.com/xMattC) |
//+------------------------------------------------------------------+
#property copyright "2025 xMattC (github.com/xMattC)"
#property link      "https://github.com/xMattC"
#property version   "1.00"

#include <MyLibs/Utils/AtrHandleManager.mqh>

// ---------------------------------------------------------------------
// ResourceManager
//
// Tracks and releases indicator handles (e.g., iMA, iRSI, iCCI).
// Delegates ATR handle management to an external AtrHandleManager instance.
//
// Usage:
// - Register indicator handles via `register_handle()`.
// - Call `release_all_handles()` to release all cached handles.
// ---------------------------------------------------------------------
class ResourceManager {
public:

    AtrHandleManager* atr_manager;

    // ---------------------------------------------------------------------
    // Registers a generic indicator handle to be released later.
    //
    // Parameters:
    // - handle : A valid (non-INVALID_HANDLE) indicator handle.
    //
    // Logic:
    // - If the handle is valid, it is added to an internal list.
    // ---------------------------------------------------------------------
    void register_handle(int handle) {
        if (handle != INVALID_HANDLE)
            add_handle(handle);
    }

    // ---------------------------------------------------------------------
    // Releases all tracked indicator resources.
    //
    // Logic:
    // - Releases generic handles tracked via `register_handle()`.
    // - Also invokes `atr_manager.release_handles()` if assigned.
    // ---------------------------------------------------------------------
    void release_all_handles() {
        release_internal_handles();   // ATR manager
        release_tracked_handles();    // Generic indicator handles
    }

private:
    int handles[];

    // ---------------------------------------------------------------------
    // Adds a handle to the internal tracking list.
    // ---------------------------------------------------------------------
    void add_handle(int handle) {
        int size = ArraySize(handles);
        ArrayResize(handles, size + 1);
        handles[size] = handle;
    }

    // ---------------------------------------------------------------------
    // Releases all tracked indicator handles (iMA, iRSI, etc.).
    // ---------------------------------------------------------------------
    void release_tracked_handles() {
        for (int i = 0; i < ArraySize(handles); i++) {
            if (handles[i] != INVALID_HANDLE)
                IndicatorRelease(handles[i]);
        }
        ArrayFree(handles);
    }

    // ---------------------------------------------------------------------
    // Releases any cached ATR handles using the external AtrHandleManager.
    // ---------------------------------------------------------------------
    void release_internal_handles() {
        if (atr_manager != NULL)
            atr_manager.release_handles();
    }
};
