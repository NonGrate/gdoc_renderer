class Pair<F, L> {
  Pair(this.left, this.right);

  final F left;
  final L right;

  @override
  String toString() => 'Pair[$left, $right]';
}