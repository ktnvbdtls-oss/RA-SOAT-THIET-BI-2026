# Triển khai trên máy chủ nội bộ 10.43.128.10

Mục tiêu: chạy công cụ tại địa chỉ nội bộ:

```text
http://10.43.128.10:8789/
```

## 1. Chuẩn bị trên máy chủ

Copy toàn bộ thư mục `device-inventory-web` sang máy chủ `10.43.128.10`, ví dụ:

```text
D:\Check_thiet_bi\device-inventory-web
```

Không nên đặt trong thư mục chỉ đọc. Tài khoản chạy server phải có quyền `Modify` đối với toàn bộ thư mục ứng dụng để ghi được `data`, `uploads`, `exports` và `logs`.

Máy chủ cần có Python 3.10+.

Nếu dùng Python hệ thống, cài thư viện:

```powershell
python -m pip install -r requirements.txt
```

Ứng dụng đã tương thích Python 3.13 và không còn sử dụng module `cgi`.

## 2. Mở firewall nội bộ

Trên máy chủ `10.43.128.10`, mở PowerShell bằng quyền Administrator, vào thư mục công cụ và chạy một lần:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\allow_firewall_intranet.ps1
```

Script này mở cổng TCP `8789` cho mạng `Domain,Private`.

## 3. Khởi động server chạy nền

Khuyến nghị double-click:

```text
start_intranet_background.bat
```

Hoặc tiếp tục dùng tên file cũ:

```text
start_intranet_server.bat
```

`start_intranet_server.bat` hiện chỉ là launcher gọi chế độ chạy nền. Sau khi báo thành công, đóng cửa sổ CMD không làm dừng hệ thống.

Sau khi báo thành công, có thể đóng cửa sổ CMD/PowerShell mà server vẫn tiếp tục chạy.

Launcher chờ tối đa 30 giây và kiểm tra endpoint nhẹ `/api/health`, tránh báo lỗi giả khi máy chủ đọc file Excel chậm.

Hoặc chạy:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\start_intranet_background.ps1
```

Để dừng server:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\stop_intranet_server.ps1
```

## 4. Tự chạy khi Windows khởi động

Mở PowerShell bằng quyền Administrator và chạy:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install_intranet_autostart.ps1
```

Script sẽ tạo Task Scheduler `VNPost Device Inventory Web`, chạy bằng tài khoản `SYSTEM` khi Windows khởi động.

Để gỡ tự khởi động:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\uninstall_intranet_autostart.ps1
```

## 5. Chạy foreground để xem lỗi trực tiếp

Chỉ dùng khi cần xem lỗi trực tiếp:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\run_intranet_server.ps1
```

Hoặc double-click:

```text
start_intranet_server.bat
```

Script foreground sẽ đặt:

- `DEVICE_INVENTORY_HOST=0.0.0.0`
- `DEVICE_INVENTORY_PORT=8789`
- `DEVICE_INVENTORY_DATA_ROOT=<thư mục công cụ>`
- `DEVICE_INVENTORY_ADMIN_PASSWORD=250389` nếu chưa đặt biến khác

## 6. Truy cập từ máy người dùng

Từ các máy trong mạng LAN/VPN nội bộ, mở:

```text
http://10.43.128.10:8789/
```

Trên chính máy chủ, có thể mở:

```text
http://127.0.0.1:8789/
```

### Tự động lấy cấu hình máy client

Trình duyệt không được phép tự đọc CPU/RAM/Serial. Agent nền phải được quản trị viên triển khai tập trung một lần bằng Group Policy hoặc PowerShell Remoting:

```text
DEPLOY_CLIENT_AGENT_GPO.md
```

Agent chạy dưới tài khoản `SYSTEM`, gửi cấu hình mỗi 15 phút. Khi người dùng mở `http://10.43.128.10:8789/`, form nhận diện IP máy client và tự điền Hostname, loại máy, hãng, model, serial, CPU, RAM, ổ cứng, Windows, Office, antivirus, IP và MAC. Người dùng không phải tải hoặc chạy file.

Dữ liệu agent có hiệu lực 60 phút để hạn chế gán nhầm khi DHCP cấp lại địa chỉ IP. Log phía client:

```text
C:\ProgramData\VNPostDeviceInventory\managed_client_agent.log
```

## 7. Đổi mật khẩu admin

Khuyến nghị đổi mật khẩu admin khi triển khai thật:

```powershell
$env:DEVICE_INVENTORY_ADMIN_PASSWORD="mat-khau-moi"
.\start_intranet_server.ps1
```

Hoặc đặt biến môi trường cấp máy trong Windows rồi khởi động lại server.

## 8. Dữ liệu và log

Dữ liệu được lưu ngay trong thư mục công cụ:

- `data\inventory.json`
- `uploads\`
- `exports\`
- `logs\intranet-server.log`

Nên sao lưu định kỳ thư mục `data`.

## 9. Kiểm tra tự động

Chạy:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\check_intranet_server.ps1
```

Script kiểm tra:

- Máy có thật sự sở hữu IP `10.43.128.10` không.
- Cổng `8789` có đang lắng nghe không.
- HTTP local và LAN có phản hồi không.
- Firewall rule đã tồn tại chưa.
- 30 dòng log lỗi cuối.

## 10. Kiểm tra lỗi thường gặp

Nếu máy khác không truy cập được:

1. Kiểm tra máy chủ đúng IP `10.43.128.10`.
2. Kiểm tra server đang chạy và cửa sổ PowerShell chưa bị đóng.
3. Chạy lại `allow_firewall_intranet.ps1` bằng quyền Administrator.
4. Kiểm tra máy người dùng cùng mạng/VPN với máy chủ.
5. Trên máy chủ thử mở `http://127.0.0.1:8789/`; nếu local không mở được thì server chưa chạy.
6. Chạy `check_intranet_server.ps1` và xem `logs\intranet-server.log`.
