const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const node22Path = path.join(__dirname, 'lib-native', 'better_sqlite3_node22.node');
const node24Path = path.join(__dirname, 'lib-native', 'better_sqlite3_node24.node');
const targetPath = path.join(__dirname, 'node_modules', 'better-sqlite3', 'build', 'Release', 'better_sqlite3.node');

console.log('🔄 Preparing Node 22 binary for standalone packaging...');
try {
  if (!fs.existsSync(node22Path)) {
    throw new Error(`Node 22 native binary not found at ${node22Path}`);
  }
  
  // Ensure target folder exists
  fs.mkdirSync(path.dirname(targetPath), { recursive: true });
  fs.copyFileSync(node22Path, targetPath);
  console.log('✅ Node 22 binary swapped successfully.');

  console.log('📦 Bundling standalone devdeck-agent.exe...');
  execSync('npx @yao-pkg/pkg . --targets node22-win-x64 --output build/devdeck-agent.exe', { stdio: 'inherit' });
  console.log('✅ Standalone executable built successfully!');

} catch (error) {
  console.error('❌ Build failed:', error.message);
} finally {
  console.log('🔄 Restoring Node 24 binary for local development...');
  try {
    if (fs.existsSync(node24Path)) {
      fs.copyFileSync(node24Path, targetPath);
      console.log('✅ Node 24 binary restored successfully.');
    } else {
      console.warn('⚠️ Node 24 native binary not found in backup to restore.');
    }
  } catch (restoreError) {
    console.error('❌ Failed to restore Node 24 binary:', restoreError.message);
  }
}
