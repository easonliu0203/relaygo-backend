# Test Auth API Endpoint
$uri = "https://api.relaygo.pro/api/auth/register-or-login"
$body = @{
    firebaseUid = "test-uid-123"
    email = "test@example.com"
    role = "customer"
    displayName = "Test User"
} | ConvertTo-Json

Write-Host "Testing Auth API Endpoint..." -ForegroundColor Cyan
Write-Host "URI: $uri" -ForegroundColor Yellow
Write-Host "Body: $body" -ForegroundColor Yellow
Write-Host ""

try {
    $response = Invoke-WebRequest -Uri $uri -Method POST -ContentType "application/json" -Body $body
    Write-Host "Status Code: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "Response:" -ForegroundColor Green
    $response.Content | ConvertFrom-Json | ConvertTo-Json -Depth 10
} catch {
    Write-Host "Error occurred:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "Response Body:" -ForegroundColor Red
        Write-Host $responseBody
    }
}

