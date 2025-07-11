#!/bin/bash
set -e

APP_NAME="icon_logo"
VERSION="$1"
GENERATE_ONLY="$2"  # 可选，值为 generate-only 时只生成 formula

BUILD_DIR="build"
FORMULA_FILE="${APP_NAME}.rb"
REPO_URL="https://github.com/zk3151463/icon_logo"
RELEASE_URL="${REPO_URL}/archive/refs/tags/v${VERSION}.tar.gz"

TAP_REPO="git@github.com:zk3151463/homebrew-icon_logo.git"
TAP_DIR="homebrew-icon_logo"
TAP_BRANCH="main"

PLATFORMS=(
  "darwin amd64"
  "darwin arm64"
  "linux amd64"
)

if [ -z "$VERSION" ]; then
  echo "❌ Usage: $0 <version> [generate-only]"
  exit 1
fi

echo "🏷️ Version: $VERSION"
echo "📝 Mode: ${GENERATE_ONLY:-full publish}"

# 清理旧文件
rm -rf "$BUILD_DIR" *.tar.gz "$FORMULA_FILE"
mkdir -p "$BUILD_DIR"

if [ "$GENERATE_ONLY" != "generate-only" ]; then
  # 创建 git tag（若不存在）
  if ! git rev-parse "v$VERSION" >/dev/null 2>&1; then
    echo "🏷️ Creating git tag v$VERSION and pushing"
    git tag "v$VERSION"
    git push origin "v$VERSION"
  else
    echo "✅ Git tag v$VERSION exists"
  fi

  echo "🛠️ Building binaries..."
  for platform in "${PLATFORMS[@]}"; do
    os=$(echo $platform | awk '{print $1}')
    arch=$(echo $platform | awk '{print $2}')
    output_dir="${BUILD_DIR}/${APP_NAME}-${VERSION}-${os}-${arch}"
    output_file="${output_dir}/${APP_NAME}"

    mkdir -p "$output_dir"
    echo "🚧 Building for $os/$arch -> $output_file"
    GOOS=$os GOARCH=$arch go build -o "$output_file" .
    tar_name="${APP_NAME}-${VERSION}-${os}-${arch}.tar.gz"
    tar -czf "$tar_name" -C "$BUILD_DIR" "$(basename $output_dir)"
  done
else
  echo "⚠️ Skipping build and upload steps (generate-only mode)"
fi

HOMEBREW_TAR="${APP_NAME}-${VERSION}-darwin-amd64.tar.gz"
if [ ! -f "$HOMEBREW_TAR" ]; then
  echo "⚠️ Warning: $HOMEBREW_TAR not found, SHA256 will be empty"
  SHA256=""
else
  SHA256=$(shasum -a 256 "$HOMEBREW_TAR" | awk '{print $1}')
fi
echo "🔐 SHA256: $SHA256"

echo "🧾 Generating Homebrew formula $FORMULA_FILE ..."
cat > "$FORMULA_FILE" <<EOF
class IconLogo < Formula
  desc "图标生成工具"
  homepage "${REPO_URL}"
  url "${RELEASE_URL}"
  sha256 "${SHA256}"
  license "MIT"

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args
  end

  test do
    assert_match "Usage", shell_output("\#{bin}/$APP_NAME --help")
  end
end
EOF

if [ "$GENERATE_ONLY" == "generate-only" ]; then
  echo "✅ Formula generated only, exiting."
  exit 0
fi

echo "🚀 Uploading release assets to GitHub..."
if gh release view v${VERSION} > /dev/null 2>&1; then
  echo "Release v${VERSION} exists. Uploading assets..."
  for f in ${APP_NAME}-${VERSION}-*.tar.gz; do
    gh release upload v${VERSION} "$f" --clobber
  done
else
  echo "Creating new release v${VERSION}..."
  gh release create v${VERSION} ${APP_NAME}-${VERSION}-*.tar.gz -t "v${VERSION}" -n "Release ${APP_NAME} version ${VERSION}"
fi

echo "📤 Pushing formula to Homebrew Tap..."
if [ ! -d "$TAP_DIR" ]; then
  git clone "$TAP_REPO" "$TAP_DIR"
fi
cd "$TAP_DIR"
git checkout "$TAP_BRANCH"
git pull origin "$TAP_BRANCH"
cp ../$FORMULA_FILE ./
git add $FORMULA_FILE
git commit -m "${APP_NAME}: update formula to v${VERSION}" || echo "⚠️ Nothing to commit"
git push origin "$TAP_BRANCH"
cd -

echo "✅ Done! Install with:"
echo "  brew tap zk3151463/icon_logo"
echo "  brew install ${APP_NAME}"
