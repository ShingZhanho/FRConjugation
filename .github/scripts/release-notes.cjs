const fs = require('node:fs');

function releaseNotes(tag) {
    const sections = fs.readFileSync('CHANGELOG.md', 'utf8').split(/^## /m).slice(1);
    const section = sections.find(value => value.split('\n', 1)[0].split(' — ', 1)[0] === tag);
    const body = section?.slice(section.indexOf('\n') + 1).trim();
    if (!body) throw new Error(`Missing CHANGELOG.md entry for ${tag}`);
    return `${body}\n`;
}

module.exports = releaseNotes;
if (require.main === module) process.stdout.write(releaseNotes(process.argv[2]));
