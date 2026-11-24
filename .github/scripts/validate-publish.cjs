// Runs inside actions/github-script. Values are data, never interpolated into shell commands.
const fs = require('node:fs');
const cp = require('node:child_process');
module.exports = async ({ core, context, github }) => {
    const manifest = JSON.parse(fs.readFileSync('typescript/package.json', 'utf8'));
    const version = manifest.version;
    if (!/^\d+\.\d+\.\d+(?:-(?:alpha|beta|rc)\.\d+)?$/.test(version)) {
        throw new Error('Use a stable version or an alpha.N/beta.N/rc.N prerelease');
    }
    const python = fs.readFileSync('python/pyproject.toml', 'utf8');
    const dotnet = fs.readFileSync('dotnet/ShingZhanho.FRConjugation/ShingZhanho.FRConjugation.csproj', 'utf8');
    const kotlin = fs.readFileSync('kotlin/build.gradle.kts', 'utf8');
    const pythonVersion = version.replace(/-alpha\./, 'a').replace(/-beta\./, 'b').replace(/-rc\./, 'rc');
    const checks = [
        [manifest.name === '@jacobshing/frconjugation', 'npm identity'],
        [/^name = "jacobszh-frconjugation"$/m.test(python), 'PyPI identity'],
        [python.match(/^version = "([^"]+)"$/m)?.[1] === pythonVersion, 'PyPI version (PEP 440)'],
        [dotnet.includes('<PackageId>ShingZhanho.FRConjugation</PackageId>'), 'NuGet identity'],
        [dotnet.includes(`<Version>${version}</Version>`), 'NuGet version'],
        [/^group = "com\.jacobshing"$/m.test(kotlin), 'Maven namespace'],
        [kotlin.match(/^version = "([^"]+)"$/m)?.[1] === version, 'Maven version'],
    ];
    for (const [ok, label] of checks) if (!ok) throw new Error(`Incorrect ${label}`);
    const sha = cp.execFileSync('git', ['rev-parse', 'HEAD'], { encoding: 'utf8' }).trim();
    const publish = process.env.PUBLISH === 'true';
    const tag = `v${version}`;
    if (publish) {
        if (context.ref !== 'refs/heads/main') throw new Error('Run the publishing workflow from main');
        if (process.env.SOURCE_REF !== tag && process.env.SOURCE_REF !== `refs/tags/${tag}`) {
            throw new Error(`Publishing requires the existing tag ${tag}; branches are build-only`);
        }
        const tagged = cp.execFileSync('git', ['rev-parse', `refs/tags/${tag}^{commit}`], { encoding: 'utf8' }).trim();
        if (sha !== tagged) throw new Error('Checkout does not match tag');
        cp.execFileSync('git', ['merge-base', '--is-ancestor', sha, 'origin/main']);
        if (['all', 'github'].includes(process.env.TARGET)) {
            require('./release-notes.cjs')(tag);
            try {
                await github.rest.repos.getReleaseByTag({ ...context.repo, tag });
                throw new Error(`GitHub release ${tag} already exists; do not overwrite it`);
            } catch (error) { if (error.status !== 404) throw error; }
        }
    }
    core.setOutput('sha', sha);
    core.setOutput('version', version);
    core.setOutput('tag', tag);
    core.setOutput('prerelease', String(version.includes('-')));
    await core.summary.addHeading(publish ? 'Publication requested' : 'Build-only validation')
        .addTable([['Commit', 'Version', 'Target'], [sha, version, process.env.TARGET]])
        .addRaw(publish ? 'Only the selected registries will publish after builds pass.' : 'No registry upload or GitHub release will occur.').write();
};
