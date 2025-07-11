#include <MyLibs/Utils/AtrHandleManager.mqh>

//+------------------------------------------------------------------+
//| ResourceManager                                                  |
//|                                                                 |
//| Tracks and releases indicator handles (iMA, iRSI, etc.)         |
//| Also delegates ATR handle cleanup to an external ATR manager    |
//+------------------------------------------------------------------+
class ResourceManager {
public:
    // --- Pointer to external ATR manager (set externally)
    //     Used for releasing any internally cached ATR handles
    AtrHandleManager* atr_manager;

    // --- Register a new indicator handle to be released later
    //     Only valid (non-INVALID_HANDLE) handles are stored
    void register_handle(int handle) {
        if (handle != INVALID_HANDLE)
            add_handle(handle);
    }

    // --- Release all tracked resources:
    void release_all_handles() {
        release_internal_handles();   // ATR manager
        release_tracked_handles();    // Generic indicator handles
    }

private:
    // --- Dynamic array of general indicator handles
    int handles[];

    // --- Append a valid indicator handle to the internal array
    //     Used by register_handle()
    void add_handle(int handle) {
        int size = ArraySize(handles);
        ArrayResize(handles, size + 1);
        handles[size] = handle;
    }

    // --- Release all generic indicator handles tracked internally
    //     This covers iMA, iRSI, iCCI, etc.
    void release_tracked_handles() {
        for (int i = 0; i < ArraySize(handles); i++) {
            if (handles[i] != INVALID_HANDLE)
                IndicatorRelease(handles[i]);
        }
        ArrayFree(handles);
    }

    // --- Release ATR handles via external AtrHandleManager
    //     No-op if atr_manager is not assigned
    void release_internal_handles() {
        if (atr_manager != NULL)
            atr_manager.release_handles();
    }
};
