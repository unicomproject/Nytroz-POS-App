enum UserStatusFilter {
  all('All'),
  active('Active'),
  inactive('Inactive'),
  invited('Invited');

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
