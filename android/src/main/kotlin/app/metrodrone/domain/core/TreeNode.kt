package app.metrodrone.domain.core

class TreeNode<V, K>(
    val name: String,
    val value: V,
    var nextNodes: Map<K, TreeNode<*, *>> = emptyMap()
)
