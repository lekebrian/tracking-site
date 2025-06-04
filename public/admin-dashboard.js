// Admin dashboard JavaScript

document.addEventListener("DOMContentLoaded", () => {
  // Check authentication
  const token = localStorage.getItem("adminToken");
  if (!token) {
    window.location.href = "admin-login.html";
    return;
  }

  // Verify token with server
  fetch("http://localhost:3001/api/admin/verify", {
    headers: {
      Authorization: `Bearer ${token}`,
    },
  })
    .then((response) => {
      if (!response.ok) {
        localStorage.removeItem("adminToken");
        window.location.href = "admin-login.html";
      }
    })
    .catch(() => {
      localStorage.removeItem("adminToken");
      window.location.href = "admin-login.html";
    });

  // Logout functionality
  const logoutBtn = document.getElementById("logoutBtn");
  if (logoutBtn) {
    logoutBtn.onclick = function () {
      localStorage.removeItem("adminToken");
      window.location.href = "admin-login.html";
    };
  }

  // Initialize dashboard
  initializeDashboard()
  loadShipments()

  // Tab functionality
  const tabButtons = document.querySelectorAll(".tab-button")
  const tabContents = document.querySelectorAll(".tab-content")

  tabButtons.forEach((button) => {
    button.addEventListener("click", function () {
      const tabName = this.dataset.tab

      // Update active tab button
      tabButtons.forEach((btn) => btn.classList.remove("active"))
      this.classList.add("active")

      // Update active tab content
      tabContents.forEach((content) => content.classList.remove("active"))
      document.getElementById(tabName + "Tab").classList.add("active")
    })
  })

  // Create shipment form
  const createForm = document.getElementById("createForm")
  createForm.addEventListener("submit", async (e) => {
    e.preventDefault()
    await createShipment()
  })

  // Edit modal functionality
  const editModal = document.getElementById("editModal")
  const closeModal = document.getElementById("closeModal")
  const cancelEdit = document.getElementById("cancelEdit")
  const editForm = document.getElementById("editForm")

  closeModal.addEventListener("click", hideEditModal)
  cancelEdit.addEventListener("click", hideEditModal)
  editModal.addEventListener("click", (e) => {
    if (e.target === editModal) {
      hideEditModal()
    }
  })

  editForm.addEventListener("submit", async (e) => {
    e.preventDefault()
    await updateShipment()
  })

  // Global variables
  let shipments = []
  let filteredShipments = []
  let editingShipmentId = null

  // Search bar functionality
  const adminSearchInput = document.getElementById("adminSearchInput")

  if (adminSearchInput) {
    adminSearchInput.addEventListener("input", handleAdminSearch)
    adminSearchInput.addEventListener("keyup", (e) => {
      if (e.key === "Enter") handleAdminSearch()
    })
  }

  function handleAdminSearch() {
    const query = adminSearchInput.value.trim().toUpperCase()
    if (!query) {
      filteredShipments = []
      displayShipments()
      return
    }
    filteredShipments = shipments.filter(s => s.id.toUpperCase().includes(query))
    // If searching, show the shipments tab
    if (filteredShipments.length > 0 || query.length > 0) {
      showShipmentsTab()
    }
    displayShipments()
  }

  // Helper to show the shipments tab
  function showShipmentsTab() {
    const tabButtons = document.querySelectorAll(".tab-button")
    const tabContents = document.querySelectorAll(".tab-content")
    tabButtons.forEach((btn) => btn.classList.remove("active"))
    tabContents.forEach((content) => content.classList.remove("active"))
    document.querySelector('[data-tab="shipments"]').classList.add("active")
    document.getElementById("shipmentsTab").classList.add("active")
  }

  // Initialize dashboard
  function initializeDashboard() {
    // Verify token
    fetch("http://localhost:3001/api/admin/verify", {
      headers: {
        Authorization: `Bearer ${token}`,
      },
    })
      .then((response) => {
        if (!response.ok) {
          localStorage.removeItem("adminToken")
          window.location.href = "admin-login.html"
        }
      })
      .catch(() => {
        localStorage.removeItem("adminToken")
        window.location.href = "admin-login.html"
      })
  }

  // Load shipments
  async function loadShipments() {
    try {
      const response = await fetch("http://localhost:3001/api/admin/shipments", {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      })

      if (response.ok) {
        shipments = await response.json()
        displayShipments()
        updateShipmentCount()
      } else {
        console.error("Failed to load shipments")
      }
    } catch (error) {
      console.error("Error loading shipments:", error)
    } finally {
      hideLoading()
    }
  }

  // Display shipments (update to use filteredShipments if present)
  function displayShipments() {
    const shipmentsList = document.getElementById("shipmentsList")
    const noShipments = document.getElementById("noShipments")
    const list = filteredShipments.length > 0 || adminSearchInput.value
      ? filteredShipments
      : shipments

    if (list.length === 0) {
      shipmentsList.innerHTML = ""
      noShipments.style.display = "block"
      return
    }

    noShipments.style.display = "none"
    shipmentsList.innerHTML = list
      .map(
        (shipment) => `
            <div class="shipment-card">
                <div class="shipment-header">
                    <div style="display: flex; align-items: center; gap: 15px;">
                        <h3 class="shipment-id">${shipment.id}</h3>
                        <div class="status-badge ${getStatusClass(shipment.status)}">
                            <span class="status-icon">${getStatusIcon(shipment.status)}</span>
                            <span class="status-text">${shipment.status}</span>
                        </div>
                    </div>
                    <div class="shipment-actions">
                        <button class="btn btn-edit" onclick="editShipment('${shipment.id}')">
                            ✏️ Edit
                        </button>
                    </div>
                </div>

                <div class="shipment-details">
                    <div class="detail-item">
                        <span class="detail-label">Description:</span>
                        <span class="detail-value">${shipment.description}</span>
                    </div>
                    <div class="detail-item">
                        <span class="detail-label">Origin:</span>
                        <span class="detail-value">${shipment.origin}</span>
                    </div>
                    <div class="detail-item">
                        <span class="detail-label">Destination:</span>
                        <span class="detail-value">${shipment.destination}</span>
                    </div>
                </div>

                <div class="shipment-status-update">
                    <label class="form-label">Update Status:</label>
                    <select class="status-select" onchange="updateStatus('${shipment.id}', this.value)" ${isUpdating(shipment.id) ? "disabled" : ""}>
                        <option value="Pending" ${shipment.status === "Pending" ? "selected" : ""}>Pending</option>
                        <option value="In Transit" ${shipment.status === "In Transit" ? "selected" : ""}>In Transit</option>
                        <option value="Delivered" ${shipment.status === "Delivered" ? "selected" : ""}>Delivered</option>
                    </select>
                    ${isUpdating(shipment.id) ? '<span class="spinner"></span>' : ""}
                </div>

                <div class="shipment-meta">
                    Created: ${new Date(shipment.created_at).toLocaleString()} | 
                    Updated: ${new Date(shipment.updated_at).toLocaleString()}
                </div>
            </div>
        `,
      )
      .join("")
  }

  // Update shipment count
  function updateShipmentCount() {
    document.getElementById("shipmentCount").textContent = shipments.length
  }

  // Hide loading spinner
  function hideLoading() {
    document.getElementById("loadingSpinner").style.display = "none"
  }

  // Generate tracking ID
  function generateTrackingId() {
    const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    let result = ""
    for (let i = 0; i < 15; i++) {
      result += chars.charAt(Math.floor(Math.random() * chars.length))
    }
    return result
  }

  // Collect all form data for creating a shipment
  async function createShipment() {
    // Collect all fields from the form
    const id = document.getElementById("trackingId").value.trim()
    const description = document.getElementById("description").value.trim()
    const origin = document.getElementById("origin").value.trim()
    const destination = document.getElementById("destination").value.trim()
    const senderName = document.getElementById("senderName").value.trim()
    const senderLocation = document.getElementById("senderLocation").value.trim()
    const senderEmail = document.getElementById("senderEmail").value.trim()
    const senderPhone = document.getElementById("senderPhone").value.trim()
    const receiverName = document.getElementById("receiverName").value.trim()
    const receiverAddress = document.getElementById("receiverAddress").value.trim()
    const receiverEmail = document.getElementById("receiverEmail").value.trim()
    const receiverPhone = document.getElementById("receiverPhone").value.trim()
    const status = document.getElementById("status").value
    const carrier = document.getElementById("carrier").value
    const shipmentType = document.getElementById("shipmentType").value
    const shipmentMode = document.getElementById("shipmentMode").value
    const weight = parseFloat(document.getElementById("weight").value)
    const numberOfBoxes = parseInt(document.getElementById("numberOfBoxes").value)
    const carrierRefNumber = document.getElementById("carrierRefNumber").value.trim()
    const productName = document.getElementById("productName").value.trim()
    const quantity = parseInt(document.getElementById("quantity").value)
    const totalFreight = parseFloat(document.getElementById("totalFreight").value)
    const expectedDeliveryDate = document.getElementById("expectedDeliveryDate").value
    const departureTime = document.getElementById("departureTime").value
    const pickUpDate = document.getElementById("pickUpDate").value
    const pickUpTime = document.getElementById("pickUpTime").value
    const comments = document.getElementById("comments").value.trim()
    const totalWeight = parseFloat(document.getElementById("totalWeight").value)
    const totalVolumetricWeight = parseFloat(document.getElementById("totalVolumetricWeight").value)
    const totalVolume = parseFloat(document.getElementById("totalVolume").value)
    const totalActualWeight = parseFloat(document.getElementById("totalActualWeight").value)

    // Collect packages
    const packages = []
    document.querySelectorAll("#packagesContainer .package-item").forEach((el) => {
      packages.push({
        quantity: parseInt(el.querySelector(".package-quantity").value),
        pieceType: el.querySelector(".package-piece-type").value,
        description: el.querySelector(".package-description").value.trim(),
      })
    })

    // Validation (add as needed)

    // Check for duplicate ID in loaded shipments
    if (shipments.some(s => s.id === id)) {
      alert("A shipment with this Tracking ID already exists. Please generate a new one.");
      return;
    }

    const createBtn = document.getElementById("createBtn")
    showButtonLoading(createBtn, true)

    try {
      const response = await fetch("http://localhost:3001/api/admin/shipments", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({
          id, description, origin, destination, senderName, senderLocation, senderEmail, senderPhone,
          receiverName, receiverAddress, receiverEmail, receiverPhone, status, carrier, shipmentType, shipmentMode,
          weight, numberOfBoxes, carrierRefNumber, productName, quantity, totalFreight, expectedDeliveryDate,
          departureTime, pickUpDate, pickUpTime, comments, totalWeight, totalVolumetricWeight, totalVolume, totalActualWeight,
          packages,
        }),
      })

      if (response.ok) {
        document.getElementById("createForm").reset()
        await loadShipments()
        document.querySelector('[data-tab="shipments"]').click()
        alert(`Shipment created successfully! Tracking ID: ${id}`)
      } else {
        const data = await response.json()
        alert(data.error || "Failed to create shipment")
      }
    } catch (error) {
      console.error("Create shipment error:", error)
      alert("Failed to create shipment. Please try again.")
    } finally {
      showButtonLoading(createBtn, false)
    }
  }

  // Update shipment status
  window.updateStatus = async (id, status) => {
    try {
      const response = await fetch(`http://localhost:3001/api/admin/shipments/${id}`, {
        method: "PUT",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({ status }),
      })

      if (response.ok) {
        await loadShipments()
      } else {
        const data = await response.json()
        alert(data.error || "Failed to update status")
      }
    } catch (error) {
      console.error("Update status error:", error)
      alert("Failed to update status. Please try again.")
    }
  }

  // Edit shipment
  window.editShipment = (id) => {
    const shipment = shipments.find((s) => s.id === id)
    if (!shipment) return

    editingShipmentId = id

    // Populate edit form
    document.getElementById("editShipmentId").textContent = id
    document.getElementById("editDescription").value = shipment.description
    document.getElementById("editOrigin").value = shipment.origin
    document.getElementById("editDestination").value = shipment.destination
    document.getElementById("editStatus").value = shipment.status

    // Show modal
    showEditModal()
  }

  // Update shipment
  async function updateShipment() {
    if (!editingShipmentId) return

    const description = document.getElementById("editDescription").value.trim()
    const origin = document.getElementById("editOrigin").value.trim()
    const destination = document.getElementById("editDestination").value.trim()
    const status = document.getElementById("editStatus").value

    const updateBtn = document.getElementById("updateBtn")
    showButtonLoading(updateBtn, true)

    try {
      const response = await fetch(`http://localhost:3001/api/admin/shipments/${editingShipmentId}`, {
        method: "PUT",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({
          description,
          origin,
          destination,
          status,
        }),
      })

      if (response.ok) {
        hideEditModal()
        await loadShipments()
        alert("Shipment updated successfully!")
      } else {
        const data = await response.json()
        alert(data.error || "Failed to update shipment")
      }
    } catch (error) {
      console.error("Update shipment error:", error)
      alert("Failed to update shipment. Please try again.")
    } finally {
      showButtonLoading(updateBtn, false)
    }
  }

  // Show edit modal
  function showEditModal() {
    editModal.style.display = "flex"
    document.body.style.overflow = "hidden"
  }

  // Hide edit modal
  function hideEditModal() {
    editModal.style.display = "none"
    document.body.style.overflow = "auto"
    editingShipmentId = null
  }

  // Show button loading state
  function showButtonLoading(button, loading) {
    const btnText = button.querySelector(".btn-text")
    const btnLoading = button.querySelector(".btn-loading")

    if (loading) {
      btnText.style.display = "none"
      btnLoading.style.display = "flex"
      button.disabled = true
    } else {
      btnText.style.display = "inline-flex"
      btnLoading.style.display = "none"
      button.disabled = false
    }
  }

  // Get status CSS class
  function getStatusClass(status) {
    switch (status) {
      case "Pending":
        return "pending"
      case "In Transit":
        return "in-transit"
      case "Delivered":
        return "delivered"
      default:
        return ""
    }
  }

  // Get status icon
  function getStatusIcon(status) {
    switch (status) {
      case "Pending":
        return "📦"
      case "In Transit":
        return "🚚"
      case "Delivered":
        return "✅"
      default:
        return "❌"
    }
  }

  // Check if shipment is being updated
  function isUpdating(id) {
    return false // Simplified for this implementation
  }

  // Tracking functionality
  const trackingInput = document.getElementById("trackingInput")
  const trackBtn = document.getElementById("trackBtn")

  if (trackingInput && trackBtn) {
    trackingInput.addEventListener("input", () => {
      // Enable only if exactly 15 characters
      trackBtn.disabled = trackingInput.value.trim().length !== 15
    })
  }

  // Auto-generate tracking ID when "Generate" button is clicked
  const generateBtn = document.getElementById("generateTrackingBtn");
  const trackingIdInput = document.getElementById("trackingId");
  if (generateBtn && trackingIdInput) {
    generateBtn.addEventListener("click", () => {
      const letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
      const numbers = "0123456789";
      let id = "";
      // First 3 characters: letters
      for (let i = 0; i < 3; i++) {
        id += letters.charAt(Math.floor(Math.random() * letters.length));
      }
      // Next 12 characters: numbers
      for (let i = 0; i < 12; i++) {
        id += numbers.charAt(Math.floor(Math.random() * numbers.length));
      }
      trackingIdInput.value = id;
      trackingIdInput.dispatchEvent(new Event("input")); // trigger validation if any
    });
  }

  // Copy Tracking ID to clipboard (desktop & mobile)
  const copyBtn = document.getElementById('copyTrackingBtn');
  // trackingIdInput is already defined above
  if (copyBtn && trackingIdInput) {
    copyBtn.addEventListener('click', function () {
      const value = trackingIdInput.value;
      if (!value) return;
      // Try Clipboard API first
      if (navigator.clipboard && window.isSecureContext) {
        navigator.clipboard.writeText(value).then(function() {
          showCopyPopup("Copied!");
        }, fallbackCopy);
      } else {
        fallbackCopy();
      }
      function fallbackCopy() {
        trackingIdInput.select();
        trackingIdInput.setSelectionRange(0, 99999); // For mobile
        try {
          document.execCommand('copy');
          showCopyPopup("Copied!");
        } catch (e) {
          alert('Failed to copy tracking number.');
        }
        window.getSelection().removeAllRanges();
      }
    });
  }
});

// Add this function at the end of your file (if not already present)
function showCopyPopup(message) {
  let popup = document.createElement("div");
  popup.textContent = message;
  popup.style.position = "fixed";
  popup.style.top = "30px";
  popup.style.right = "30px";
  popup.style.background = "#333";
  popup.style.color = "#fff";
  popup.style.padding = "12px 24px";
  popup.style.borderRadius = "6px";
  popup.style.boxShadow = "0 2px 8px rgba(0,0,0,0.15)";
  popup.style.fontSize = "1rem";
  popup.style.zIndex = 9999;
  popup.style.opacity = "0";
  popup.style.transition = "opacity 0.3s";

  document.body.appendChild(popup);

  // Fade in
  setTimeout(() => {
    popup.style.opacity = "1";
  }, 10);

  // Fade out and remove after 1.5s
  setTimeout(() => {
    popup.style.opacity = "0";
    setTimeout(() => {
      popup.remove();
    }, 300);
  }, 1500);
}
