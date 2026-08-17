class BrandListQuery {
  const BrandListQuery({
    this.search = '',
    this.pageNumber = 1,
    this.pageSize = 5,
  });

  final String search;
  final int pageNumber;
  final int pageSize;
}
