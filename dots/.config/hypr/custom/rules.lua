-- Float the QR popup from custom/scripts/qr-clip.sh.
-- Matched on the filename rather than class = imv, so ordinary imv windows
-- (opening an image normally) keep their usual tiled behaviour.
hl.window_rule({ match = { title = "^(.*)(qr-clip\\.png)(.*)$" }, float = true })
hl.window_rule({ match = { title = "^(.*)(qr-clip\\.png)(.*)$" }, center = true })
hl.window_rule({ match = { title = "^(.*)(qr-clip\\.png)(.*)$" }, size = { "420", "420" } })
