class BufferUtils {

public:
   double get_latest_buffer_value(int handle);
   double get_buffer_value(int handle, int shift);
};


// ---- IMPLEMENTATION BELOW ----

/**
 * Get the most recent value from the specified indicator buffer.
 *
 * param handle: Indicator handle (must be valid and previously created)
 * return: Most recent buffer value (shift 0), or 0.0 if retrieval fails
 */
double BufferUtils::get_latest_buffer_value(int handle) {
   double val[];
   ArraySetAsSeries(val, true);

   if (CopyBuffer(handle, 0, 0, 1, val) == 1)
      return val[0];

   return 0.0;
}


/**
 * Get a specific historical value from the specified indicator buffer.
 *
 * param handle: Indicator handle
 * param shift: Bar index (0 = current, 1 = previous, etc.)
 * return: Buffer value at shift, or 0.0 if retrieval fails
 */
double BufferUtils::get_buffer_value(int handle, int shift) {
   double val[];
   ArraySetAsSeries(val, true);

   if (CopyBuffer(handle, 0, shift, 1, val) == 1)
      return val[0];

   return 0.0;
}
