# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# Must be declared before inheriting dotnet-pkg.
DOTNET_PKG_COMPAT="9.0"

NUGETS="
	castle.core@4.4.1
	commandlineparser@2.9.1
	config.net@4.19.0
	goaaats.steamworks@2.3.4
	hexa.net.imgui@2.2.9
	hexa.net.imgui.backends.sdl3@1.0.18
	hexa.net.sdl3@1.2.16
	hexa.net.sdl3.image@1.0.0
	hexagen.runtime@1.1.18
	hexagen.runtime@1.1.21
	keysharp@1.0.5
	microsoft.aspnetcore.app.ref@9.0.12
	microsoft.aspnetcore.app.runtime.linux-x64@9.0.12
	microsoft.codeanalysis.analyzers@3.3.3
	microsoft.codeanalysis.bannedapianalyzers@3.3.4
	microsoft.codeanalysis.bannedapianalyzers@4.14.0
	microsoft.codeanalysis.common@4.0.1
	microsoft.codeanalysis.csharp@4.0.1
	microsoft.codeanalysis.netanalyzers@9.0.0
	microsoft.codeanalysis.netanalyzers@10.0.101
	microsoft.net.illink.tasks@9.0.12
	microsoft.netcore.app.host.linux-x64@9.0.12
	microsoft.netcore.app.ref@9.0.12
	microsoft.netcore.app.runtime.linux-x64@9.0.12
	microsoft.netcore.platforms@1.1.0
	microsoft.netcore.targets@1.1.0
	microsoft.win32.primitives@4.3.0
	microsoft.win32.registry@6.0.0-preview.5.21301.5
	microsoft.win32.systemevents@6.0.0
	netstandard.library@1.6.1
	netstandard.library@2.0.3
	newtonsoft.json@13.0.3
	pinvoke.kernel32@0.7.124
	pinvoke.windows.core@0.7.124
	runtime.any.system.collections@4.3.0
	runtime.any.system.diagnostics.tools@4.3.0
	runtime.any.system.diagnostics.tracing@4.3.0
	runtime.any.system.globalization@4.3.0
	runtime.any.system.globalization.calendars@4.3.0
	runtime.any.system.io@4.3.0
	runtime.any.system.reflection@4.3.0
	runtime.any.system.reflection.extensions@4.3.0
	runtime.any.system.reflection.primitives@4.3.0
	runtime.any.system.resources.resourcemanager@4.3.0
	runtime.any.system.runtime@4.3.0
	runtime.any.system.runtime.handles@4.3.0
	runtime.any.system.runtime.interopservices@4.3.0
	runtime.any.system.text.encoding@4.3.0
	runtime.any.system.text.encoding.extensions@4.3.0
	runtime.any.system.threading.tasks@4.3.0
	runtime.any.system.threading.timer@4.3.0
	runtime.debian.8-x64.runtime.native.system.security.cryptography.openssl@4.3.0
	runtime.fedora.23-x64.runtime.native.system.security.cryptography.openssl@4.3.0
	runtime.fedora.24-x64.runtime.native.system.security.cryptography.openssl@4.3.0
	runtime.native.system@4.3.0
	runtime.native.system.io.compression@4.3.0
	runtime.native.system.net.http@4.3.0
	runtime.native.system.security.cryptography.apple@4.3.0
	runtime.native.system.security.cryptography.openssl@4.3.0
	runtime.opensuse.13.2-x64.runtime.native.system.security.cryptography.openssl@4.3.0
	runtime.opensuse.42.1-x64.runtime.native.system.security.cryptography.openssl@4.3.0
	runtime.osx.10.10-x64.runtime.native.system.security.cryptography.apple@4.3.0
	runtime.osx.10.10-x64.runtime.native.system.security.cryptography.openssl@4.3.0
	runtime.rhel.7-x64.runtime.native.system.security.cryptography.openssl@4.3.0
	runtime.ubuntu.14.04-x64.runtime.native.system.security.cryptography.openssl@4.3.0
	runtime.ubuntu.16.04-x64.runtime.native.system.security.cryptography.openssl@4.3.0
	runtime.ubuntu.16.10-x64.runtime.native.system.security.cryptography.openssl@4.3.0
	runtime.unix.microsoft.win32.primitives@4.3.0
	runtime.unix.system.console@4.3.0
	runtime.unix.system.diagnostics.debug@4.3.0
	runtime.unix.system.io.filesystem@4.3.0
	runtime.unix.system.net.primitives@4.3.0
	runtime.unix.system.net.sockets@4.3.0
	runtime.unix.system.private.uri@4.3.0
	runtime.unix.system.runtime.extensions@4.3.0
	serilog@4.0.0
	serilog@4.1.0
	serilog@4.2.0
	serilog@4.3.0
	serilog.enrichers.sensitive@1.7.3
	serilog.enrichers.thread@4.0.0
	serilog.sinks.async@2.1.0
	serilog.sinks.console@6.0.0
	serilog.sinks.debug@3.0.0
	serilog.sinks.file@6.0.0
	serilog.sinks.file@7.0.0
	sharedmemory@2.3.2
	system.appcontext@4.3.0
	system.buffers@4.3.0
	system.buffers@4.5.1
	system.collections@4.3.0
	system.collections.concurrent@4.3.0
	system.collections.immutable@5.0.0
	system.collections.nongeneric@4.3.0
	system.collections.specialized@4.3.0
	system.componentmodel@4.3.0
	system.componentmodel.primitives@4.3.0
	system.componentmodel.typeconverter@4.3.0
	system.configuration.configurationmanager@6.0.0
	system.console@4.3.0
	system.diagnostics.debug@4.3.0
	system.diagnostics.diagnosticsource@4.3.0
	system.diagnostics.tools@4.3.0
	system.diagnostics.tracesource@4.3.0
	system.diagnostics.tracing@4.3.0
	system.drawing.common@6.0.0
	system.dynamic.runtime@4.3.0
	system.globalization@4.3.0
	system.globalization.calendars@4.3.0
	system.globalization.extensions@4.3.0
	system.io@4.3.0
	system.io.compression@4.3.0
	system.io.compression.zipfile@4.3.0
	system.io.filesystem@4.3.0
	system.io.filesystem.primitives@4.3.0
	system.linq@4.3.0
	system.linq.expressions@4.3.0
	system.memory@4.5.4
	system.memory@4.6.0
	system.net.http@4.3.0
	system.net.nameresolution@4.3.0
	system.net.primitives@4.3.0
	system.net.sockets@4.3.0
	system.numerics.vectors@4.4.0
	system.objectmodel@4.3.0
	system.private.uri@4.3.0
	system.reflection@4.3.0
	system.reflection.emit@4.3.0
	system.reflection.emit.ilgeneration@4.3.0
	system.reflection.emit.lightweight@4.3.0
	system.reflection.emit.lightweight@4.7.0
	system.reflection.extensions@4.3.0
	system.reflection.metadata@5.0.0
	system.reflection.primitives@4.3.0
	system.reflection.typeextensions@4.3.0
	system.resources.resourcemanager@4.3.0
	system.runtime@4.3.0
	system.runtime.compilerservices.unsafe@4.5.2
	system.runtime.compilerservices.unsafe@4.5.3
	system.runtime.compilerservices.unsafe@5.0.0
	system.runtime.extensions@4.3.0
	system.runtime.handles@4.3.0
	system.runtime.interopservices@4.3.0
	system.runtime.interopservices.runtimeinformation@4.3.0
	system.runtime.numerics@4.3.0
	system.security.accesscontrol@6.0.0
	system.security.accesscontrol@6.0.0-preview.5.21301.5
	system.security.cryptography.algorithms@4.3.0
	system.security.cryptography.cng@4.3.0
	system.security.cryptography.csp@4.3.0
	system.security.cryptography.encoding@4.3.0
	system.security.cryptography.openssl@4.3.0
	system.security.cryptography.primitives@4.3.0
	system.security.cryptography.protecteddata@6.0.0
	system.security.cryptography.x509certificates@4.3.0
	system.security.permissions@6.0.0
	system.security.principal.windows@4.3.0
	system.security.principal.windows@6.0.0-preview.5.21301.5
	system.text.encoding@4.3.0
	system.text.encoding.codepages@4.5.1
	system.text.encoding.extensions@4.3.0
	system.text.json@9.0.2
	system.text.regularexpressions@4.3.0
	system.threading@4.3.0
	system.threading.tasks@4.3.0
	system.threading.tasks.extensions@4.3.0
	system.threading.tasks.extensions@4.5.4
	system.threading.threadpool@4.3.0
	system.threading.timer@4.3.0
	system.windows.extensions@6.0.0
	system.xml.readerwriter@4.3.0
	system.xml.xdocument@4.3.0
	system.xml.xmldocument@4.3.0
"

# xdg must be inherited to get pkg_preinst/pkg_postinst/pkg_postrm hooks that
# call update-desktop-database and gtk-update-icon-cache; without them the
# .desktop entry and icon are never registered with GNOME (or any other
# XDG-compliant desktop environment).
inherit dotnet-pkg git-r3 xdg

DESCRIPTION="Custom launcher for Final Fantasy XIV Online (rankynbass fork with Proton and Wine switcher support)"
HOMEPAGE="https://github.com/rankynbass/XIVLauncher.Core"

EGIT_REPO_URI="https://github.com/rankynbass/XIVLauncher.Core.git"
EGIT_BRANCH="RB-patched"
EGIT_SUBMODULES=( "lib/FFXIVQuickLauncher" )

SRC_URI="${NUGET_URIS}"

LICENSE="GPL-3 MIT"
SLOT="0"
KEYWORDS=""

IUSE=""

RDEPEND="
	net-misc/aria2
	dev-libs/libunwind
	app-arch/zstd
	virtual/dotnet-sdk:${DOTNET_PKG_COMPAT}
"
BDEPEND="${RDEPEND}"

DOTNET_PKG_PROJECTS=( "${S}/src/XIVLauncher.Core/XIVLauncher.Core.csproj" )

DOTNET_PKG_BUILD_EXTRA_ARGS=( -p:BuildHash=9999-gentoo )

PROPERTIES="live"
RESTRICT="mirror"

# Both dotnet-pkg and git-r3 export src_unpack; git-r3 (inherited last) would
# win and skip the NuGet cache setup entirely, causing NU1301 errors at restore
# time.  Call both explicitly.
src_unpack() {
	dotnet-pkg_src_unpack
	git-r3_src_unpack
}

src_prepare() {
	# Remove any global.json files (including the one from the submodule) so
	# that the SDK version is not pinned to a specific patch release.
	find "${S}" -maxdepth 3 -name "global.json" -delete || die
	dotnet-pkg_src_prepare
}

src_compile() {
	edotnet publish \
		"${DOTNET_PKG_PROJECTS[@]}" \
		--no-restore \
		--no-self-contained \
		--configuration "$(dotnet-pkg-base_get-configuration)" \
		--runtime "${DOTNET_PKG_RUNTIME}" \
		--output "${DOTNET_PKG_OUTPUT}" \
		--verbosity "${DOTNET_VERBOSITY}" \
		-maxCpuCount:$(makeopts_jobs) \
		"${DOTNET_PKG_BUILD_EXTRA_ARGS[@]}"
}

src_install() {
	local instdir="/usr/share/${P}"

	dodir "${instdir}"
	cp -r "${DOTNET_PKG_OUTPUT}"/. "${ED}/${instdir}/" || die

	dotnet-pkg-base_dolauncher "${instdir}/XIVLauncher.Core" xivlauncher

	domenu misc/linux_distrib/XIVLauncher.desktop

	# Install into the hicolor theme so that GNOME's icon resolver finds it.
	# Without -s the icon lands in /usr/share/pixmaps which GNOME ignores;
	# with -s 512 it lands in /usr/share/icons/hicolor/512x512/apps/ and the
	# xdg eclass will run gtk-update-icon-cache in pkg_postinst.
	newicon -s 512 misc/linux_distrib/512.png xivlauncher.png

	einstalldocs
}
