const fs = require('fs');
const path = require('path');

const libDir = path.join(__dirname, 'lib');

function walkDir(dir, callback) {
  fs.readdirSync(dir).forEach(f => {
    let dirPath = path.join(dir, f);
    let isDirectory = fs.statSync(dirPath).isDirectory();
    isDirectory ? walkDir(dirPath, callback) : callback(path.join(dir, f));
  });
}

walkDir(libDir, function(filePath) {
  if (filePath.endsWith('.dart') && !filePath.includes('api_config.dart')) {
    let content = fs.readFileSync(filePath, 'utf8');
    let original = content;

    // Pattern 1: http://10.155.83.53:8000/api -> ${ApiConfig.baseUrl}
    content = content.replace(/http:\/\/10\.155\.83\.53:8000\/api/g, '${ApiConfig.baseUrl}');
    
    // Pattern 2: "http://10.155.83.53:8000" + -> "${ApiConfig.baseUrl.replaceAll('/api', '')}" +
    content = content.replace(/"http:\/\/10\.155\.83\.53:8000"\s*\+/g, `"\${ApiConfig.baseUrl.replaceAll('/api', '')}" +`);
    
    // Pattern 3: "http://10.155.83.53:8000" (standalone, e.g., waiting_card.dart)
    content = content.replace(/"http:\/\/10\.155\.83\.53:8000"/g, `ApiConfig.baseUrl.replaceAll('/api', '')`);

    if (content !== original) {
      // Add import if missing
      if (!content.includes('ApiConfig') || !content.includes('api_config.dart')) {
          // calculate relative path depth
          let relative = path.relative(path.dirname(filePath), path.join(libDir, 'services/api_config.dart')).replace(/\\/g, '/');
          
          let importStr = `import '${relative}';\n`;
          // insert after the last import, or at top
          let lastImportResult = [...content.matchAll(/^import .*;$/gm)];
          if (lastImportResult.length > 0) {
              let lastMatch = lastImportResult[lastImportResult.length - 1];
              let insertIndex = lastMatch.index + lastMatch[0].length;
              content = content.substring(0, insertIndex) + '\n' + importStr + content.substring(insertIndex);
          } else {
              content = importStr + content;
          }
      }
      fs.writeFileSync(filePath, content, 'utf8');
      console.log('Updated', filePath);
    }
  }
});
console.log('Done');
