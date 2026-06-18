# Nytroz POS — நாம் என்ன செய்தோம்? (Tamil விளக்கம்)

**தேதி:** 17 ஜூன் 2026  
**Project:** Nytroz POS — Tenant Admin (Backend + Flutter App)

---

## சுருக்கம் (Summary)

இந்த session-ல் **Tenant Admin Outlet** feature-க்கு **Backend API** முழுமையாக build பண்ணோம், **Flutter app**-ல permission-based UI + **Outlet Submit bug fix** பண்ணோம்.

**2 Git Branches:**
| Project | Branch | Repo Path |
|---------|--------|-----------|
| Backend (.NET) | `dashboard_tenant` | `Back end/Nytroz-POS-Backend` |
| Flutter App | `tenant-dashboard` | `Tenantadmin/Nytroz-POS-App` |

---

## 1. Backend — என்ன செய்தோம்?

### Outlet API Endpoints (Permission-based)

| Method | URL | வேலை |
|--------|-----|------|
| GET | `/api/v1/tenant-admin/outlets/summary` | Outlet metrics summary |
| GET | `/api/v1/tenant-admin/outlets` | Outlet list (paginated) |
| POST | `/api/v1/tenant-admin/outlets` | புதிய outlet create |
| GET | `/api/v1/tenant-admin/outlets/{id}` | Outlet details |
| PUT | `/api/v1/tenant-admin/outlets/{id}` | Outlet update |
| PATCH | `/api/v1/tenant-admin/outlets/{id}/status` | Status change |
| DELETE | `/api/v1/tenant-admin/outlets/{id}` | Outlet delete |

### Security Rules
- JWT token-ல இருந்து **Tenant ID** + **User ID** எடுக்கும் — request body-ல அனுப்பக்கூடாது
- **Permission codes** மட்டும் use (role name hardcode இல்ல)
- User-க்கு permission இல்லாத field-ஐ response-ல **hide** பண்ணும் (zero value காட்டாது)

### Dev Seed Data
- Tenant Admin outlet permissions automatically seed ஆகும் (development)
- Test login:
  - **Email:** `tenantadmin001@gmail.com`
  - **Tenant:** `TENANT001`

### Windows Dev Run Fix
- Desktop path-ல build lock problem fix
- `run-dev.ps1` — backend start
- `stop-dev.ps1` — port 5052 stop
- API URL: `http://localhost:5052`

### Create Outlet — Backend எதிர்பார்க்கும் JSON
```json
{
  "name": "Outlet Name",
  "code": "OUT001",
  "addressLine1": "Street",
  "addressLine2": null,
  "city": "Colombo",
  "postalCode": "00100",
  "country": "Sri Lanka",
  "phone": "0771234567",
  "email": "outlet@gmail.com",
  "status": "Active"
}
```

---

## 2. Flutter App — என்ன செய்தோம்?

### A. Permission-based Outlet UI
- Menu, buttons, table columns — எல்லாம் **permission config**-ல define
- User permission இல்லாம outlet create/edit/delete buttons காட்டாது
- Route guard — permission இல்லாம page open ஆகாது

### B. Outlet Submit Bug Fix (முக்கிய fix)

**Problem:** Submit click பண்ணினா "எதுவும் நடக்கல" — user-க்கு error தெரியல

**Root Causes:**
1. Flutter **தவறான API URL** use பண்ணிச்சு (`/api/tenant-admin/...` instead of `/api/v1/tenant-admin/...`)
2. Flutter **தவறான JSON field names** அனுப்பிச்சு (`outletName` instead of `name`)
3. Backend response `{ success, data: {...} }` wrapper-ஐ parse பண்ணல
4. Validation error (e.g. invalid email) Review step-ல **காட்டல**

**Fixes:**
- API path → `/api/v1/tenant-admin/outlets`
- JSON mapping → backend format-க்கு match
- Response `data` unwrap
- Error SnackBar show (Tamil: bottom-ல message வரும்)
- Invalid email-க்கு auto step 1-க்கு jump + field error show
- Form-ல email validation add

### C. Other UI Fixes
- Permission aliases syntax error fix (`tenant_admin_permission_aliases.dart`)
- Metric card overflow fix (tablet layout)
- GoRouter crash fix (`TenantAdminLayout` — `currentPath` pass)

### App API Config
- Default base URL: `http://10.0.2.2:5052` (Android emulator → localhost)
- Real device-க்கு `--dart-define=API_BASE_URL=http://YOUR_PC_IP:5052`

---

## 3. Outlet Submit — எப்படி Test பண்ண?

1. Backend run: `Back end/Nytroz-POS-Backend` folder-ல `.\run-dev.ps1`
2. Flutter run: `Tenantadmin/Nytroz-POS-App` folder-ல `flutter run`
3. Login: `tenantadmin001@gmail.com`
4. **Outlets → Add outlet**
5. Form fill:
   - **Valid email** கட்டாயம்: `test@gmail.com` ( `fdh` மாதிரி invalid email வேண்டாம் )
   - Name, Code, Address, City, Country, Postal code fill பண்ணுங்கள்
6. Review → **Submit**
7. Success → Outlet detail page open ஆகும்

---

## 4. Submit Fail ஆனா என்ன Check பண்ண?

| Symptom | Reason | Solution |
|---------|--------|----------|
| Bottom-ல "Email is invalid" | Email format தவறு | `name@domain.com` format use |
| "Failed to create outlet" | Backend off | `run-dev.ps1` run பண்ணுங்கள் |
| 403 Forbidden | Permission இல்ல | Dev seed migration run பண்ணுங்கள் |
| 409 Conflict | Same outlet code exists | Different code use பண்ணுங்கள் |

---

## 5. முக்கிய Files (Reference)

### Backend
- `src/SCS.Api/Modules/TenantAdmin/TenantAdminOutletsController.cs`
- `src/SCS.Application/Modules/TenantAdmin/Services/TenantAdminOutletService.cs`
- `src/SCS.Infrastructure/Modules/TenantAdmin/TenantAdminOutletRepository.cs`

### Flutter
- `lib/features/tenant_admin/outlets/data/datasources/outlet_remote_datasource.dart`
- `lib/features/tenant_admin/outlets/data/models/create_outlet_request_dto.dart`
- `lib/features/tenant_admin/outlets/presentation/widgets/outlet_form.dart`
- `lib/features/tenant_admin/outlets/presentation/utils/outlet_api_errors.dart`
- `lib/core/access/tenant_admin_permission_aliases.dart`

---

## 6. Branch Update Status

இந்த file-ஓடு சேர்த்து எல்லா changes-உம் commit பண்ணப்பட்டது:

- **Backend branch:** `dashboard_tenant`
- **Flutter branch:** `tenant-dashboard`

Remote-க்கு push பண்ண `--` user permission வேண்டும்:
```powershell
# Backend
cd "Back end\Nytroz-POS-Backend"
git push origin dashboard_tenant

# Flutter
cd "Tenantadmin\Nytroz-POS-App"
git push origin tenant-dashboard
```

---

## 7. Database Migration (Backend)

Backend first time run பண்ணினா migration apply பண்ணுங்கள்:
```powershell
cd "Back end\Nytroz-POS-Backend\src\SCS.Api"
dotnet ef database update
```

---

**Questions இருந்தா கேளுங்கள் — outlet, dashboard, permissions எதுவும் explain பண்ணலாம்.**
