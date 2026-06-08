# Triển khai công cụ rà soát thiết bị CNTT lên Internet bằng GitHub + Render

Tài liệu này dùng cho thư mục `device-inventory-web`.

## 1. Chuẩn bị GitHub

1. Cài Git for Windows nếu máy chưa có lệnh `git`: https://git-scm.com/download/win
2. Tạo repository mới trên GitHub. Nên chọn `Private` vì đây là công cụ nội bộ.
3. Mở PowerShell tại thư mục gốc dự án và chạy:

```powershell
git init
git add device-inventory-web
git commit -m "Deploy device inventory web tool"
git branch -M main
git remote add origin https://github.com/<tai-khoan>/<ten-repo>.git
git push -u origin main
```

Nếu repo đã tồn tại sẵn, chỉ cần:

```powershell
git add device-inventory-web
git commit -m "Prepare device inventory web for internet deployment"
git push
```

## 2. Deploy lên Render

1. Vào https://render.com và đăng nhập bằng GitHub.
2. Chọn `New` -> `Blueprint`.
3. Chọn repository vừa push.
4. Render sẽ đọc file `device-inventory-web/render.yaml`.
5. Khi Render hỏi biến môi trường `DEVICE_INVENTORY_ADMIN_PASSWORD`, nhập mật khẩu admin mới, không dùng `250389`.
6. Tạo service và chờ build xong.

Sau khi hoàn tất, Render cấp URL dạng:

```text
https://vnpost-device-inventory.onrender.com
```

## 3. Cấu hình đang dùng trên cloud

Ứng dụng tự nhận biến `PORT` của Render và bind `0.0.0.0`.

Các biến quan trọng:

- `DEVICE_INVENTORY_ADMIN_PASSWORD`: mật khẩu quản trị.
- `DEVICE_INVENTORY_DATA_ROOT=/var/data`: thư mục lưu dữ liệu lâu dài.
- `DEVICE_INVENTORY_HOST=0.0.0.0`: cho phép truy cập từ Internet.

Render disk được mount tại `/var/data`, dùng để giữ:

- `/var/data/data/inventory.json`
- `/var/data/uploads`
- `/var/data/exports`

## 4. Kiểm tra sau deploy

1. Mở URL Render.
2. Gửi thử một phiếu khảo sát.
3. Bấm `Đăng nhập quản trị`.
4. Nhập mật khẩu đã đặt trong Render.
5. Kiểm tra danh sách dữ liệu và bấm `Xuất Excel mẫu`.

## 5. Lưu ý bảo mật

- Không đưa mật khẩu admin vào source code hoặc GitHub.
- Không dùng mật khẩu mặc định `250389` khi chạy public. Server đã có cơ chế từ chối chạy public nếu chưa đặt biến `DEVICE_INVENTORY_ADMIN_PASSWORD`.
- Nên để GitHub repository ở chế độ Private.
- Không commit dữ liệu thật trong `data`, `uploads`, `exports`; các thư mục này đã được `.gitignore`.

## 6. Chạy local vẫn giữ nguyên

```powershell
.\start_tool.ps1
```

Local URL mặc định:

```text
http://127.0.0.1:8789/
```
