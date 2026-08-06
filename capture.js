const puppeteer = require('puppeteer');
const fs = require('fs');

(async () => {
  const browser = await puppeteer.launch({ headless: 'new' });
  const page = await browser.newPage();
  await page.setViewport({ width: 1600, height: 900 });

  await page.goto('http://localhost:8080/tenant-admin/outlets#/tenant-login', { waitUntil: 'networkidle2' });
  
  // Wait for canvas to render
  await new Promise(r => setTimeout(r, 4000));

  try {
    // Click email
    await page.mouse.click(1000, 450);
    await new Promise(r => setTimeout(r, 500));
    await page.keyboard.type('admin@nytroz.local');
    
    // Click password
    await page.mouse.click(1000, 580);
    await new Promise(r => setTimeout(r, 500));
    await page.keyboard.type('Admin@12345');
    
    // Click Sign In
    await page.mouse.click(1000, 750);
    
    // Wait for navigation and rendering
    await new Promise(r => setTimeout(r, 6000));
  } catch (e) {
    console.log('Login action error:', e.message);
  }

  // Go to outlets page just in case
  await page.goto('http://localhost:8080/tenant-admin/outlets', { waitUntil: 'networkidle2' });
  await new Promise(r => setTimeout(r, 6000));
  
  if (!fs.existsSync('artifacts')){
      fs.mkdirSync('artifacts');
  }
  await page.screenshot({ path: 'artifacts/task4b_outlets_1600x900.png' });
  console.log('Screenshot saved to artifacts/task4b_outlets_1600x900.png');
  await browser.close();
})();
