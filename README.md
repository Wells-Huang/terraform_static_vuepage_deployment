## 專案簡介
將客戶的Vue專案 (https://github.com/Wells-Huang/my-vue-app)部署到S3上, 
並使用 cloudfront 作為 CDN 服務

此專案為S3及Cloudfront的建置
s3需要為private, 禁止public存取

## 使用說明
在wsl環境下
- 執行terraform init
- 執行terraform apply
成功後輸出 s3_bucket_name 以及 cloudfront URL.

## 驗證步驟:
terraform apply執行完畢後

客戶專案 ( https://github.com/Wells-Huang/my-vue-app) 所在的Dist目錄

透過 aws s3 sync dist/ s3://[your-bucket-name]/ --delete 命令, 手動上傳檔案

之後可透過 cloudfront URL顯示此vue網頁

## 驗證完成後的清理
驗證成功後，執行 terraform destroy清除已經建立的所有元件

