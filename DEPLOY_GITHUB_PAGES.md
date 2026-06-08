# Hướng dẫn triển khai GitHub Pages (Miễn phí)

URL sau khi deploy: **https://nguyennam90.github.io/Check_thiet_bi/**

---

## Bước 1 – Tạo GitHub Personal Access Token (Fine-grained)

Token này cho phép ứng dụng ghi dữ liệu phiếu vào repo.

1. Đăng nhập GitHub → vào https://github.com/settings/tokens?type=beta
2. Nhấn **Generate new token**
3. Đặt tên: `device-inventory-write`
4. Expiration: chọn ngày hết hạn (tối đa 1 năm)
5. Repository access → **Only select repositories** → chọn `Check_thiet_bi`
6. Permissions → **Repository permissions** → **Contents** → chọn **Read and Write**
7. Nhấn **Generate token** → **sao chép token** (hiển thị 1 lần duy nhất)

---

## Bước 2 – Dán token vào github-config.js

Mở file `static/github-config.js` và thay dòng:

```js
writeToken: "PASTE_YOUR_FINE_GRAINED_PAT_HERE",
```

Thành:

```js
writeToken: "github_pat_xxxxxxxxxxxxxxxxxxxx",  // token vừa tạo
```

---

## Bước 3 – Push code lên GitHub

Mở PowerShell tại thư mục gốc chứa `device-inventory-web/` và chạy:

```powershell
# Nếu chưa init git:
cd "c:\Users\ADMIN\Documents\Phần mềm lấy dữ liệu doanh thu BCCP\device-inventory-web"
git init
git remote add origin https://github.com/nguyennam90/Check_thiet_bi.git
git checkout -b main

# Commit và push:
git add .
git commit -m "Deploy: chuyen sang GitHub Pages"
git push -u origin main
```

> Nếu repo đã có code cũ, chỉ cần:
> ```powershell
> git add .
> git commit -m "Chuyen sang web tinh GitHub Pages"
> git push
> ```

---

## Bước 4 – Bật GitHub Pages

1. Vào https://github.com/nguyennam90/Check_thiet_bi/settings/pages
2. **Source** → chọn **GitHub Actions**
3. Lưu lại

GitHub Actions sẽ tự động chạy workflow `.github/workflows/pages.yml` và deploy thư mục `static/` lên GitHub Pages.

---

## Bước 5 – Kiểm tra sau deploy

1. Chờ 1–2 phút để GitHub Actions chạy xong (xem tại tab **Actions**)
2. Mở https://nguyennam90.github.io/Check_thiet_bi/
3. Thử gửi 1 phiếu test → kiểm tra file `data/inventory.json` trong repo được cập nhật
4. Đăng nhập quản trị bằng GitHub Personal Access Token (cùng token đã tạo ở Bước 1)
5. Kiểm tra xuất Excel

---

## Bước 6 – Cấu hình lay_thong_tin.bat trên các máy nhân viên

File `lay_thong_tin.bat` đã được cập nhật URL mới:

```
https://nguyennam90.github.io/Check_thiet_bi
```

Phân phối file này (hoặc `client_collector.bat`) cho từng máy nhân viên. Khi chạy:
- Script thu thập thông tin phần cứng (hostname, CPU, RAM, ổ cứng, IP, MAC, serial...)
- Mở trình duyệt mặc định với URL GitHub Pages, tự động điền form
- Nhân viên chỉ cần điền thêm thông tin người dùng (tên, bưu cục, bộ phận) rồi nhấn **Gửi phiếu**

---

## Lưu ý bảo mật

| Điểm | Giải thích |
|---|---|
| Token trong `github-config.js` | Có thể xem được trong source code (public repo). Token chỉ có quyền **ghi vào 1 file** trong 1 repo. Rủi ro thấp cho công cụ nội bộ. |
| Token admin | Nhập khi đăng nhập, chỉ lưu trong `sessionStorage` của trình duyệt, tự xóa khi đóng tab. |
| Dữ liệu `inventory.json` | Hiển thị công khai vì repo public. Nếu dữ liệu nhạy cảm, hãy dùng repo private (cần GitHub Pro). |

---

## Cập nhật code sau này

Mỗi khi bạn push code mới lên branch `main`, GitHub Actions sẽ tự động deploy lại:

```powershell
git add .
git commit -m "Cap nhat noi dung"
git push
```

---

## Chạy local vẫn được

Nếu muốn test local, chỉ cần mở thẳng file `static/index.html` trong trình duyệt.
Lưu ý: trình duyệt không cho phép đọc file local qua `fetch()`, nên cần dùng một local server nhỏ:

```powershell
# Python 3
python -m http.server 8080 --directory static
# Mở: http://localhost:8080/
```
