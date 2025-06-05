// Main website JavaScript

document.addEventListener("DOMContentLoaded", () => {
  // Mobile menu dropdown logic
  const mobileMenuBtn = document.querySelector(".mobile-menu-btn")
  const mobileNavDropdown = document.getElementById("mobileNavDropdown")

  // Toggle dropdown
  mobileMenuBtn.addEventListener("click", (e) => {
    e.stopPropagation()
    const isOpen = mobileNavDropdown.style.display === "block"
    mobileNavDropdown.style.display = isOpen ? "none" : "block"
  })

  // Close dropdown when clicking outside
  document.addEventListener("click", (e) => {
    if (
      mobileNavDropdown.style.display === "block" &&
      !mobileNavDropdown.contains(e.target) &&
      e.target !== mobileMenuBtn
    ) {
      mobileNavDropdown.style.display = "none"
    }
  })

  // Close dropdown when a link is clicked
  mobileNavDropdown.querySelectorAll("a").forEach((link) => {
    link.addEventListener("click", () => {
      mobileNavDropdown.style.display = "none"
    })
  })

  // Smooth scrolling for anchor links
  document.querySelectorAll('a[href^="#"]').forEach((anchor) => {
    anchor.addEventListener("click", function (e) {
      e.preventDefault()
      const target = document.querySelector(this.getAttribute("href"))
      if (target) {
        target.scrollIntoView({
          behavior: "smooth",
          block: "start",
        })
      }
    })
  })

  // Tracking form functionality
  const trackingForm = document.getElementById("trackingForm")
  const trackingIdInput = document.getElementById("trackingId")
  const trackBtn = document.getElementById("trackBtn")
  const errorMessage = document.getElementById("errorMessage")
  const trackingResult = document.getElementById("trackingResult")

  if (trackingForm) {
    // Auto-uppercase and format tracking ID input
    trackingIdInput.addEventListener("input", (e) => {
      e.target.value = e.target.value.toUpperCase().replace(/[^A-Z0-9]/g, "")

      // Enable/disable track button based on input length
      const isValid = e.target.value.length === 15
      trackBtn.disabled = !isValid
    })

    // Handle form submission
    trackingForm.addEventListener("submit", async (e) => {
      e.preventDefault()

      const trackingId = trackingIdInput.value.trim()
      if (trackingId.length !== 15) {
        showError("Please enter a valid 9-character tracking ID")
        return
      }

      await trackPackage(trackingId)
    })
  }

  // Track package function
  async function trackPackage(trackingId) {
    showLoading(true)
    hideError()
    hideResult()

    try {
      const response = await fetch(`http://localhost:3001/api/track/${trackingId}`)
      const data = await response.json()

      if (response.ok) {
        showResult(data)
      } else {
        showError(data.error || "Tracking ID not found")
      }
    } catch (error) {
      console.error("Tracking error:", error)
      showError("Failed to track shipment. Please check your connection and try again.")
    } finally {
      showLoading(false)
    }
  }

  // Show loading state
  function showLoading(loading) {
    const btnText = trackBtn.querySelector(".btn-text")
    const btnLoading = trackBtn.querySelector(".btn-loading")

    if (loading) {
      btnText.style.display = "none"
      btnLoading.style.display = "flex"
      trackBtn.disabled = true
    } else {
      btnText.style.display = "inline-flex"
      btnLoading.style.display = "none"
      trackBtn.disabled = trackingIdInput.value.length !== 15
    }
  }

  // Show error message
  function showError(message) {
    const errorText = errorMessage.querySelector(".error-text")
    errorText.textContent = message
    errorMessage.style.display = "flex"
  }

  // Hide error message
  function hideError() {
    errorMessage.style.display = "none"
  }

  // Show tracking result
  function showResult(data) {
    // Basic information
    document.getElementById("resultId").textContent = data.id
    document.getElementById("resultDescription").textContent = data.description || "N/A"
    document.getElementById("resultOrigin").textContent = data.origin || "N/A"
    document.getElementById("resultDestination").textContent = data.destination || "N/A"
    document.getElementById("resultCarrier").textContent = data.carrier || "N/A"
    document.getElementById("resultExpectedDelivery").textContent = data.expectedDeliveryDate
      ? new Date(data.expectedDeliveryDate).toLocaleDateString()
      : "N/A"
    document.getElementById("resultUpdated").textContent = new Date(data.updated_at).toLocaleString()

    // Set status badge
    const statusBadge = document.getElementById("statusBadge")
    const statusIcon = document.getElementById("statusIcon")
    const statusText = document.getElementById("statusText")

    statusText.textContent = data.status
    statusBadge.className = "status-badge " + getStatusClass(data.status)
    statusIcon.textContent = getStatusIcon(data.status)

    // Update timeline
    updateTimeline(data.status)

    // Sender information
    document.getElementById("resultSenderName").textContent = data.senderName || "N/A"
    document.getElementById("resultSenderLocation").textContent = data.senderLocation || "N/A"
    document.getElementById("resultSenderEmail").textContent = data.senderEmail || "N/A"
    document.getElementById("resultSenderPhone").textContent = data.senderPhone || "N/A"

    // Receiver information
    document.getElementById("resultReceiverName").textContent = data.receiverName || "N/A"
    document.getElementById("resultReceiverAddress").textContent = data.receiverAddress || "N/A"
    document.getElementById("resultReceiverEmail").textContent = data.receiverEmail || "N/A"
    document.getElementById("resultReceiverPhone").textContent = data.receiverPhone || "N/A"

    // Shipment details
    document.getElementById("resultShipmentType").textContent = data.shipmentType || "N/A"
    document.getElementById("resultShipmentMode").textContent = data.shipmentMode || "N/A"
    document.getElementById("resultWeight").textContent = data.weight ? `${data.weight} kg` : "N/A"
    document.getElementById("resultNumberOfBoxes").textContent = data.numberOfBoxes || "N/A"
    document.getElementById("resultCarrierRef").textContent = data.carrierRefNumber || "N/A"
    document.getElementById("resultProduct").textContent = data.productName || "N/A"
    document.getElementById("resultQuantity").textContent = data.quantity || "N/A"
    document.getElementById("resultTotalFreight").textContent = data.totalFreight ? `$${data.totalFreight}` : "N/A"

    // Dates & Times
    document.getElementById("resultExpectedDeliveryFull").textContent = data.expectedDeliveryDate
      ? new Date(data.expectedDeliveryDate).toLocaleString()
      : "N/A"
    document.getElementById("resultDepartureTime").textContent = data.departureTime || "N/A"
    document.getElementById("resultPickUpDate").textContent = data.pickUpDate
      ? new Date(data.pickUpDate).toLocaleDateString()
      : "N/A"
    document.getElementById("resultPickUpTime").textContent = data.pickUpTime || "N/A"

    // Total information
    document.getElementById("resultTotalWeight").textContent = data.totalWeight ? `${data.totalWeight} kg` : "N/A"
    document.getElementById("resultTotalVolumetricWeight").textContent = data.totalVolumetricWeight
      ? `${data.totalVolumetricWeight} kg`
      : "N/A"
    document.getElementById("resultTotalVolume").textContent = data.totalVolume ? `${data.totalVolume} m³` : "N/A"
    document.getElementById("resultTotalActualWeight").textContent = data.totalActualWeight
      ? `${data.totalActualWeight} kg`
      : "N/A"

    // Comments
    document.getElementById("resultComments").textContent = data.comments || "No comments available"

    // Packages
    const packagesTableBody = document.getElementById("packagesTableBody")
    packagesTableBody.innerHTML = ""

    if (data.packages && data.packages.length > 0) {
      data.packages.forEach((pkg) => {
        const row = document.createElement("tr")
        row.innerHTML = `
          <td>${pkg.quantity || "N/A"}</td>
          <td>${pkg.pieceType || "N/A"}</td>
          <td>${pkg.description || "N/A"}</td>
        `
        packagesTableBody.appendChild(row)
      })
    } else {
      const row = document.createElement("tr")
      row.innerHTML = `<td colspan="3" class="text-center">No package information available</td>`
      packagesTableBody.appendChild(row)
    }

    // History
    const historyTimeline = document.getElementById("historyTimeline")
    historyTimeline.innerHTML = ""

    if (data.history && data.history.length > 0) {
      data.history.forEach((entry) => {
        const historyEntry = document.createElement("div")
        historyEntry.className = "history-entry"
        historyEntry.innerHTML = `
          <div class="history-entry-header">
            <div class="history-entry-date">${new Date(entry.date).toLocaleDateString()} ${entry.time}</div>
            <div class="history-entry-status ${getStatusClass(entry.status)}">${entry.status}</div>
          </div>
          <div class="history-entry-location">${entry.location}</div>
          <div class="history-entry-remarks">${entry.remarks || ""}</div>
          <div class="history-entry-updated">Updated by: ${entry.updatedBy}</div>
        `
        historyTimeline.appendChild(historyEntry)
      })
    } else {
      historyTimeline.innerHTML = `<div class="text-center">No history information available</div>`
    }

    // Show result
    trackingResult.style.display = "block"
  }

  // Hide tracking result
  function hideResult() {
    trackingResult.style.display = "none"
  }

  // Get status CSS class
  function getStatusClass(status) {
    switch (status) {
      case "Pending":
        return "pending"
      case "In Transit":
        return "in-transit"
      case "On Hold":
        return "on-hold"
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
      case "On Hold":
        return "⏸️"
      case "Delivered":
        return "✅"
      default:
        return "❌"
    }
  }

  // Update timeline based on status
  function updateTimeline(currentStatus) {
    const timelineItems = document.querySelectorAll(".timeline-item")
    const statusOrder = ["Pending", "In Transit", "On Hold", "Delivered"]
    const currentIndex = statusOrder.indexOf(currentStatus)

    timelineItems.forEach((item, index) => {
      item.classList.remove("active")
      if (index <= currentIndex) {
        item.classList.add("active")
      }
    })
  }

  // Add some interactive animations
  const statCards = document.querySelectorAll(".stat-card")
  statCards.forEach((card) => {
    card.addEventListener("mouseenter", function () {
      this.style.transform = "translateY(-10px) scale(1.02)"
    })

    card.addEventListener("mouseleave", function () {
      this.style.transform = "translateY(0) scale(1)"
    })
  })

  // Service cards hover effect
  const serviceCards = document.querySelectorAll(".service-card")
  serviceCards.forEach((card) => {
    card.addEventListener("mouseenter", function () {
      this.style.transform = "translateY(-10px)"
      this.style.boxShadow = "0 15px 30px rgba(0, 0, 0, 0.2)"
    })

    card.addEventListener("mouseleave", function () {
      this.style.transform = "translateY(0)"
      this.style.boxShadow = "0 5px 15px rgba(0, 0, 0, 0.1)"
    })
  })

  // Result tabs functionality
  document.querySelectorAll(".result-tab-button").forEach((button) => {
    button.addEventListener("click", function () {
      const tabName = this.getAttribute("data-tab")

      // Update active tab button
      document.querySelectorAll(".result-tab-button").forEach((btn) => {
        btn.classList.remove("active")
      })
      this.classList.add("active")

      // Update active tab content
      document.querySelectorAll(".result-tab-content").forEach((content) => {
        content.classList.remove("active")
      })
      document.getElementById(tabName + "Tab").classList.add("active")
    })
  })

  // Check for tracking ID in URL parameters
  function checkUrlForTrackingId() {
    const urlParams = new URLSearchParams(window.location.search)
    const trackingId = urlParams.get("track")

    if (trackingId) {
      document.getElementById("trackingId").value = trackingId
      document.getElementById("trackBtn").click()
    }
  }

  // Call this function when the page loads
  checkUrlForTrackingId()
})
