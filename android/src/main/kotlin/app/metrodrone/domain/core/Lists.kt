package app.metrodrone.domain.core


inline fun <reified T> List<T>.findFirstAndUpdate(
    predicate: (T) -> Boolean,
    transform: (T) -> T,
): List<T> {
    val index = this.indexOfFirst { predicate(it) }.takeIf { it != -1 } ?: return this
    val mutable = this.toMutableList()
    val itemToUpdate = this.getOrNull(index) ?: return this
    mutable[index] = transform(itemToUpdate)
    return mutable.toList()
}

inline fun <reified R, reified T> List<T>.findFirstInstanceAndUpdate(
    crossinline predicate: (R) -> Boolean,
    crossinline transform: (R) -> R
): List<T> = this.findFirstAndUpdate(
    predicate = { it is R && predicate(it) },
    transform = { (it as? R)?.let { r -> transform(r) as? T ?: it } ?: it }
)

fun <T> List<T>.addToImmutable(element: T, index: Int = size): List<T> =
    this.toMutableList().apply { add(index, element) }.toList()

fun <T> List<T>.addStartToImmutable(element: T): List<T> = addToImmutable(element, 0)

fun <T> List<T>.updateAt(index: Int, transform: (T) -> T): List<T> {
    if (index < 0 || index > lastIndex) return this
    val updated = toMutableList()
    updated[index] = transform(get(index))
    return updated
}

inline fun <reified R, reified T> List<T>.findFirstUpdateAndMoveTop(
    crossinline predicate: (R) -> Boolean,
    crossinline transform: (R) -> R
): List<T> {
    val index = indexOfFirst { it is R && predicate(it) }.takeIf { it != -1 } ?: return this
    val item = get(index) as? R ?: return this
    val updatedItem = transform(item) as T
    val newList = toMutableList()
    newList.removeAt(index)
    newList.add(0, updatedItem)
    return newList
}


