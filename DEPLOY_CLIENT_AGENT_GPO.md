# Triển khai agent máy client không cần người dùng thao tác

## Nguyên tắc

Website không thể trực tiếp đọc CPU, RAM, serial và phần mềm cài đặt của máy người dùng. Agent `managed_client_agent.ps1` được quản trị viên cài tập trung dưới tài khoản `SYSTEM`, tự gửi cấu hình đến máy chủ mỗi 15 phút.

Khi người dùng mở `http://10.43.128.10:8789/`, form nhận diện địa chỉ IP của máy và tự điền cấu hình mới nhất. Người dùng không tải hoặc chạy file.

Dữ liệu chỉ được dùng trong 60 phút; agent cập nhật mỗi 15 phút để hạn chế gán nhầm khi DHCP cấp lại IP.

## Phương án 1: Group Policy

Đây là phương án ưu tiên khi các máy tham gia Windows Domain.

1. Sao chép hai file sau vào thư mục dùng chung mà tài khoản máy tính có quyền đọc, ví dụ:

```text
\\TEN-MIEN\SYSVOL\TEN-MIEN\scripts\VNPostDeviceAgent\
```

- `managed_client_agent.ps1`
- `install_managed_client_agent.ps1`

2. Mở `Group Policy Management`.
3. Tạo GPO `VNPost Device Inventory Agent` và liên kết với OU chứa máy tính cần khảo sát.
4. Vào:

```text
Computer Configuration
  > Windows Settings
  > Scripts (Startup/Shutdown)
  > Startup
```

5. Thêm chương trình:

```text
powershell.exe
```

6. Đặt tham số:

```text
-NoProfile -ExecutionPolicy Bypass -File "\\TEN-MIEN\SYSVOL\TEN-MIEN\scripts\VNPostDeviceAgent\install_managed_client_agent.ps1" -ServerUrl "http://10.43.128.10:8789"
```

7. Chạy `gpupdate /force` hoặc chờ máy khởi động lại.

GPO chạy dưới ngữ cảnh máy tính nên người dùng không cần quyền Administrator và không thấy cửa sổ cài đặt.

## Phương án 2: PowerShell Remoting

Dùng khi chưa có GPO nhưng các máy đã bật WinRM. Trên máy quản trị, mở PowerShell bằng tài khoản quản trị miền:

```powershell
cd "C:\duong-dan\device-inventory-web"
.\deploy_managed_agent_remote.ps1 -ComputerName PC001,PC002,PC003
```

Hoặc lấy danh sách máy từ file:

```powershell
$may = Get-Content .\danh_sach_may.txt
.\deploy_managed_agent_remote.ps1 -ComputerName $may
```

## Kiểm tra trên máy client

Task Scheduler phải có tác vụ:

```text
VNPost Device Inventory Agent
```

Agent và log nằm tại:

```text
C:\ProgramData\VNPostDeviceInventory\
```

Kiểm tra thủ công:

```powershell
Get-ScheduledTask -TaskName "VNPost Device Inventory Agent"
Get-Content "C:\ProgramData\VNPostDeviceInventory\managed_client_agent.log" -Tail 20
```

## Gỡ agent

Chạy `uninstall_managed_client_agent.ps1` bằng quyền Administrator hoặc triển khai script này bằng GPO Computer Shutdown.

## Điều kiện mạng

Máy client phải truy cập được:

```text
http://10.43.128.10:8789/api/client-inventory
```

Nếu hệ thống đi qua reverse proxy hoặc NAT làm nhiều máy có cùng một IP nguồn, cơ chế nhận diện theo IP không còn chính xác. Trong mạng LAN trực tiếp hiện tại, mỗi máy cần có một IP riêng.
