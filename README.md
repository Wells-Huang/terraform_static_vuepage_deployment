# Terraform Static Vue Page Deployment

本專案使用 Terraform 將 Vue.js 靜態網站自動化部署至 AWS S3，並透過 CloudFront CDN 進行全球加速與 HTTPS 傳輸。

## 架構說明

本部署方案包含以下 AWS 資源：

-   **AWS S3 (Simple Storage Service)**
    -   作為靜態網站的儲存來源 (Origin)。
    -   配置為 **Private** (私有)，禁止任何公開存取 (Block Public Access)。
-   **AWS CloudFront**
    -   作為 CDN (內容傳遞網路) 分發靜態內容。
    -   透過 **OAC (Origin Access Control)** 安全地存取 S3 Bucket，確保使用者僅能透過 CloudFront 訪問網站。
    -   自動強制 HTTP 轉導至 HTTPS。

## 前置需求 (Prerequisites)

在此專案開始之前，請確保您的環境已安裝並設定以下工具：

-   **WSL (Windows Subsystem for Linux) / Linux / macOS** (建議環境)
-   **Terraform** (>= 1.0.0)
-   **AWS CLI** (已設定 `aws configure` 並具備相應權限)
-   **Vue 專案建置產物** (即 `dist` 資料夾)
    -   可參考範例專案: [my-vue-app](https://github.com/Wells-Huang/my-vue-app)

## 快速開始 (Quick Start)

### 1. 初始化 Terraform

在專案根目錄下，初始化 Terraform backend 與 provider plugin：

```bash
terraform init
```

### 2. 配置變數

開啟 `main.tf` 或建立 `terraform.tfvars` 檔案，確認或修改 `s3_bucket_name` 變數。
**注意**：S3 Bucket 名稱必須是**全球唯一**的。

```hcl
# main.tf variable block
variable "s3_bucket_name" {
  description = "S3 bucket name for vue app deployment"
  default     = "your-unique-bucket-name-here" 
}
```

### 3. 部署基礎設施

執行計畫並套用變更：

```bash
terraform apply
```

確認計畫無誤後，輸入 `yes` 繼續。
部署完成後，Terminal 將會輸出以下重要資訊：

-   `s3_bucket_name`: 您的 S3 Bucket 名稱
-   `cloudfront_domain_name`: CloudFront 分發的網域名稱 (例如 `d123456abcdef.cloudfront.net`)

## 應用程式部署

基礎設施建立完成後，您需要將 Vue 專案的靜態檔案上傳至 S3。

### 1. 準備靜態檔案

請確保您已有 Vue 專案的 `dist` 目錄。若使用範例專案：

```bash
# 在 Vue 專案目錄下
npm install
npm run build
# 確認 dist 目錄已產生
```

### 2. 上傳至 S3

使用 AWS CLI 將 `dist` 目錄同步至 S3 Bucket。請將 `[your-bucket-name]` 替換為 `terraform apply` 輸出的 `s3_bucket_name`。

```bash
aws s3 sync ./dist s3://[your-bucket-name] --delete
```

-   `--delete`: 會刪除 S3 上存在但 `dist` 中沒有的檔案，保持同步。

### 3. 驗證網站

打開瀏覽器，訪問 `terraform apply` 輸出的 `cloudfront_domain_name` (例如 `https://d123456abcdef.cloudfront.net`)。
您應該能看到您的 Vue 應用程式首頁。

## 清理資源 (Clean Up)

驗證完成後，若不再需要此環境，請務必執行清理以避免產生額外費用。

**重要：Terraform 預設無法刪除含有物件的 S3 Bucket。**

1.  **清空 S3 Bucket**

    ```bash
    aws s3 rm s3://[your-bucket-name] --recursive
    ```

2.  **銷毀基礎設施**

    ```bash
    terraform destroy
    ```

    輸入 `yes` 確認銷毀所有資源。

## 疑難排解 (Troubleshooting)

-   **403 Forbidden / Access Denied**:
    -   請稍待幾分鐘，CloudFront 的變更 (如 OAC 權限傳播) 可能需要一點時間生效。
    -   確認 S3 Bucket Policy 是否已正確設定為僅允許 CloudFront OAC 存取。
-   **502 Bad Gateway / 504 Gateway Timeout**:
    -   檢查 CloudFront Origin 設定是否正確指向 S3 Regional Domain。
