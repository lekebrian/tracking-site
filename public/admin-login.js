// Admin login JavaScript

document.addEventListener("DOMContentLoaded", () => {
  const loginForm = document.getElementById("loginForm")
  const usernameInput = document.getElementById("username")
  const passwordInput = document.getElementById("password")
  const loginBtn = document.getElementById("loginBtn")
  const loginError = document.getElementById("loginError")

  // Handle form submission
  loginForm.addEventListener("submit", async (e) => {
    e.preventDefault()

    const username = usernameInput.value.trim()
    const password = passwordInput.value.trim()

    if (!username || !password) {
      showError("Please enter both username and password")
      return
    }

    await login(username, password)
  })

  // Login function
  async function login(username, password) {
    showLoading(true)
    hideError()

    try {
      const response = await fetch("http://localhost:3001/api/admin/login", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ username, password }),
      })

      const data = await response.json()

      if (response.ok) {
        // Store token in localStorage
        localStorage.setItem("adminToken", data.token)

        // Redirect to dashboard
        window.location.href = "admin-dashboard.html"
      } else {
        showError(data.error || "Login failed")
      }
    } catch (error) {
      console.error("Login error:", error)
      showError("Login failed. Please check your connection and try again.")
    } finally {
      showLoading(false)
    }
  }

  // Show loading state
  function showLoading(loading) {
    const btnText = loginBtn.querySelector(".btn-text")
    const btnLoading = loginBtn.querySelector(".btn-loading")

    if (loading) {
      btnText.style.display = "none"
      btnLoading.style.display = "flex"
      loginBtn.disabled = true
    } else {
      btnText.style.display = "inline"
      btnLoading.style.display = "none"
      loginBtn.disabled = false
    }
  }

  // Show error message
  function showError(message) {
    const errorText = loginError.querySelector(".error-text")
    errorText.textContent = message
    loginError.style.display = "block"
  }

  // Hide error message
  function hideError() {
    loginError.style.display = "none"
  }

  // Check if already logged in
  const token = localStorage.getItem("adminToken")
  if (token) {
    // Verify token with server before redirecting
    fetch("http://localhost:3001/api/admin/verify", {
      headers: { Authorization: `Bearer ${token}` },
    })
      .then((res) => {
        if (res.ok) {
          window.location.href = "admin-dashboard.html"
        }
        // else, stay on login page and let user log in
      })
      .catch(() => {
        // stay on login page
      })
  }
})