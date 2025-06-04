const express = require("express")
const cors = require("cors")
const jwt = require("jsonwebtoken")
const path = require("path")
const mysql = require("mysql2/promise")

const app = express()
const PORT = process.env.PORT || 3001
const JWT_SECRET = process.env.JWT_SECRET || "your-secret-key-change-in-production"

// Middleware
app.use(cors())
app.use(express.json())
app.use(express.static("public"))

// MySQL database connection
const db = mysql.createPool({
  host: "localhost",
  user: "root", // change as needed
  password: "", // change as needed
  database: "tnt_tracking",
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
})

// Helper: get full shipment details (with packages and history)
async function getShipmentDetails(id) {
  // Get main shipment
  const [shipments] = await db.query("SELECT * FROM shipments WHERE id = ?", [id])
  if (!shipments.length) return null
  const shipment = shipments[0]

  // Get packages
  const [packages] = await db.query("SELECT * FROM packages WHERE shipment_id = ?", [id])
  // Map package fields to camelCase
  shipment.packages = packages.map(pkg => ({
    id: pkg.id,
    shipmentId: pkg.shipment_id,
    quantity: pkg.quantity,
    pieceType: pkg.piece_type,
    description: pkg.description,
  }))

  // Get history
  const [history] = await db.query("SELECT * FROM shipment_history WHERE shipment_id = ? ORDER BY date DESC, time DESC", [id])
  // Map history fields to camelCase
  shipment.history = history.map(h => ({
    id: h.id,
    shipmentId: h.shipment_id,
    date: h.date,
    time: h.time,
    location: h.location,
    status: h.status,
    updatedBy: h.updated_by,
    remarks: h.remarks,
  }))

  // Map shipment fields to camelCase for frontend
  return {
    id: shipment.id,
    description: shipment.description,
    origin: shipment.origin,
    destination: shipment.destination,
    carrier: shipment.carrier,
    expectedDeliveryDate: shipment.expected_delivery_date,
    updated_at: shipment.updated_at,
    status: shipment.status,
    senderName: shipment.sender_name,
    senderLocation: shipment.sender_location,
    senderEmail: shipment.sender_email,
    senderPhone: shipment.sender_phone,
    receiverName: shipment.receiver_name,
    receiverAddress: shipment.receiver_address,
    receiverEmail: shipment.receiver_email,
    receiverPhone: shipment.receiver_phone,
    shipmentType: shipment.shipment_type,
    shipmentMode: shipment.shipment_mode,
    weight: shipment.weight,
    numberOfBoxes: shipment.number_of_boxes,
    carrierRefNumber: shipment.carrier_ref_number,
    productName: shipment.product_name,
    quantity: shipment.quantity,
    totalFreight: shipment.total_freight,
    departureTime: shipment.departure_time,
    pickUpDate: shipment.pick_up_date,
    pickUpTime: shipment.pick_up_time,
    totalWeight: shipment.total_weight,
    totalVolumetricWeight: shipment.total_volumetric_weight,
    totalVolume: shipment.total_volume,
    totalActualWeight: shipment.total_actual_weight,
    comments: shipment.comments,
    packages: shipment.packages,
    history: shipment.history,
  }
}

// Demo admin credentials
const ADMIN_CREDENTIALS = {
  username: "admin",
  password: "admin123",
}

// Middleware to verify JWT token
function verifyToken(req, res, next) {
  const authHeader = req.headers.authorization
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return res.status(401).json({ error: "Unauthorized" })
  }

  const token = authHeader.substring(7)
  try {
    const decoded = jwt.verify(token, JWT_SECRET)
    req.user = decoded
    next()
  } catch (error) {
    return res.status(401).json({ error: "Invalid token" })
  }
}

// Routes

// Public tracking route
app.get("/api/track/:id", async (req, res) => {
  try {
    const trackingId = req.params.id
    if (!/^[A-Z0-9]{9,15}$/.test(trackingId)) {
      return res.status(400).json({ error: "Invalid tracking ID format." })
    }
    const shipment = await getShipmentDetails(trackingId)
    if (!shipment) return res.status(404).json({ error: "Tracking ID not found" })
    res.json(shipment)
  } catch (error) {
    console.error("Tracking error:", error)
    res.status(500).json({ error: "Internal server error" })
  }
})

// Admin login
app.post("/api/admin/login", (req, res) => {
  try {
    const { username, password } = req.body

    if (username !== ADMIN_CREDENTIALS.username || password !== ADMIN_CREDENTIALS.password) {
      return res.status(401).json({ error: "Invalid credentials" })
    }

    const token = jwt.sign({ username, role: "admin" }, JWT_SECRET, { expiresIn: "24h" })
    res.json({ token, message: "Login successful" })
  } catch (error) {
    console.error("Login error:", error)
    res.status(500).json({ error: "Internal server error" })
  }
})

// Verify admin token
app.get("/api/admin/verify", verifyToken, (req, res) => {
  res.json({ valid: true, user: req.user })
})

// Get all shipments (admin)
app.get("/api/admin/shipments", verifyToken, async (req, res) => {
  try {
    const [rows] = await db.query("SELECT * FROM shipments ORDER BY created_at DESC")
    res.json(rows)
  } catch (error) {
    console.error("Get shipments error:", error)
    res.status(500).json({ error: "Internal server error" })
  }
})

// Create new shipment (admin)
app.post("/api/admin/shipments", verifyToken, async (req, res) => {
  try {
    const s = req.body
    // Insert into shipments
    await db.query(
      `INSERT INTO shipments 
      (id, description, origin, destination, sender_name, sender_location, sender_email, sender_phone, receiver_name, receiver_address, receiver_email, receiver_phone, status, carrier, shipment_type, shipment_mode, weight, number_of_boxes, carrier_ref_number, product_name, quantity, total_freight, expected_delivery_date, departure_time, pick_up_date, pick_up_time, total_weight, total_volumetric_weight, total_volume, total_actual_weight, comments)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        s.id, s.description, s.origin, s.destination, s.senderName, s.senderLocation, s.senderEmail, s.senderPhone,
        s.receiverName, s.receiverAddress, s.receiverEmail, s.receiverPhone, s.status, s.carrier, s.shipmentType, s.shipmentMode,
        s.weight, s.numberOfBoxes, s.carrierRefNumber, s.productName, s.quantity, s.totalFreight, s.expectedDeliveryDate,
        s.departureTime, s.pickUpDate, s.pickUpTime, s.totalWeight, s.totalVolumetricWeight, s.totalVolume, s.totalActualWeight, s.comments
      ]
    )
    // Insert packages
    if (Array.isArray(s.packages)) {
      for (const pkg of s.packages) {
        await db.query(
          "INSERT INTO packages (shipment_id, quantity, piece_type, description) VALUES (?, ?, ?, ?)",
          [s.id, pkg.quantity, pkg.pieceType, pkg.description]
        )
      }
    }
    // Insert initial history
    await db.query(
      "INSERT INTO shipment_history (shipment_id, date, time, location, status, updated_by, remarks) VALUES (?, CURDATE(), CURTIME(), ?, ?, ?, ?)",
      [s.id, s.origin, s.status, req.user.username, "Shipment created"]
    )
    res.status(201).json({ success: true })
  } catch (error) {
    console.error("Create shipment error:", error)
    res.status(500).json({ error: "Internal server error" })
  }
})

// Update shipment (admin)
app.put("/api/admin/shipments/:id", verifyToken, async (req, res) => {
  try {
    const id = req.params.id
    const s = req.body
    await db.query(
      `UPDATE shipments SET description=?, origin=?, destination=?, sender_name=?, sender_location=?, sender_email=?, sender_phone=?, receiver_name=?, receiver_address=?, receiver_email=?, receiver_phone=?, status=?, carrier=?, shipment_type=?, shipment_mode=?, weight=?, number_of_boxes=?, carrier_ref_number=?, product_name=?, quantity=?, total_freight=?, expected_delivery_date=?, departure_time=?, pick_up_date=?, pick_up_time=?, total_weight=?, total_volumetric_weight=?, total_volume=?, total_actual_weight=?, comments=?, updated_at=NOW() WHERE id=?`,
      [
        s.description, s.origin, s.destination, s.senderName, s.senderLocation, s.senderEmail, s.senderPhone,
        s.receiverName, s.receiverAddress, s.receiverEmail, s.receiverPhone, s.status, s.carrier, s.shipmentType, s.shipmentMode,
        s.weight, s.numberOfBoxes, s.carrierRefNumber, s.productName, s.quantity, s.totalFreight, s.expectedDeliveryDate,
        s.departureTime, s.pickUpDate, s.pickUpTime, s.totalWeight, s.totalVolumetricWeight, s.totalVolume, s.totalActualWeight, s.comments, id
      ]
    )
    // Optionally update packages/history here as well
    res.json({ success: true })
  } catch (error) {
    console.error("Update shipment error:", error)
    res.status(500).json({ error: "Internal server error" })
  }
})

// Serve static files
app.get("/", (req, res) => {
  res.sendFile(path.join(__dirname, "public", "index.html"))
})

// Start server
app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`)
})
