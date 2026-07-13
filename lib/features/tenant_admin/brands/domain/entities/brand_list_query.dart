class BrandListQuery {
  const BrandListQuery({
    this.search = '',
    this.pageNumber = 1,
    this.pageSize = 50,
  });

  final String search;
  final int pageNumber;
  final int pageSize;
}
