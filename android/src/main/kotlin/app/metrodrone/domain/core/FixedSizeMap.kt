package app.metrodrone.domain.core

class FixedSizeMap<K, V>(
    private val maxSize: Int
) : LinkedHashMap<K, V>(
    /* initialCapacity = */ maxSize,
    /* loadFactor = */ 0.75f,
    /* accessOrder = */ false
) {
    override fun removeEldestEntry(eldest: MutableMap.MutableEntry<K, V>): Boolean {
        return size > maxSize
    }
}
