enum UserStatusFilter {
  all('All'),
  active('Active'),
  invited('Invited'),
  inactive('Inactive');

  const UserStatusFilter(this.label);

  final String label;

  String? get apiStatus {
    switch (this) {
      case UserStatusFilter.all:
        return null;
      case UserStatusFilter.active:
        return 'ACTIVE';
      case UserStatusFilter.inactive:
        return 'INACTIVE';
      case UserStatusFilter.invited:
        return 'INVITED';
    }
  }
}
