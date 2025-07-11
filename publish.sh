#!/bin/bash
set -e

APP_NAME="icon_logo"
VERSION="$1"
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
  echo "❌ 用法: $0 <version>，例如: ./publish.sh 1.2.3"
  exit 1
fi

# 创建 git tag（若不存在）
if ! git rev-parse "v$VERSION" >/dev/null 2>&1; then
  echo "🏷️ 创建 git tag v$VERSION 并推送"
  git tag "v$VERSION"
  git push origin "v$VERSION"
else
  echo "✅ Git tag v$VERSION 已存在"
fi

# 清理旧文件
rm -rf "$BUILD_DIR" *.tar.gz "$FORMULA_FILE"
mkdir -p "$BUILD_DIR"

# 多平台构建
echo "🛠️ 构建多个平台版本..."
for platform in "${PLATFORMS[@]}"; do
  os=$(echo $platform | awk '{print $1}')
  arch=$(echo $platform | awk '{print $2}')
  output_dir="${BUILD_DIR}/${APP_NAME}-${VERSION}-${os}-${arch}"
  output_file="${output_dir}/${APP_NAME}"

  mkdir -p "$output_dir"
  echo "🚧 构建: $os/$arch -> $output_file"
  GOOS=$os GOARCH=$arch go build -o "$output_file" .
  tar_name="${APP_NAME}-${VERSION}-${os}-${arch}.tar.gz"
  tar -czf "$tar_name" -C "$BUILD_DIR" "$(basename $output_dir)"
done

# Homebrew 用 tar.gz
HOMEBREW_TAR="${APP_NAME}-${VERSION}-darwin-amd64.tar.gz"
echo "🔐 计算 SHA256..."
SHA256=$(shasum -a 256 "$HOMEBREW_TAR" | awk '{print $1}')
echo "SHA256: $SHA256"

# 生成 Formula 文件
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

# 上传 GitHub Release
echo "🚀 上传 Release 到 GitHub..."
if gh release view v${VERSION} > /dev/null 2>&1; then
  echo "🔁 Release 已存在，覆盖上传构建文件"
  for f in ${APP_NAME}-${VERSION}-*.tar.gz; do
    gh release upload v${VERSION} "$f" --clobber
  done
else
  echo "🆕 创建 Release 并上传构建文件"
  gh release create v${VERSION} ${APP_NAME}-${VERSION}-*.tar.gz \
    -t "v${VERSION}" -n "发布 $APP_NAME v${VERSION}"
fi

# 推送 Formula 到 Tap
echo "📤 推送 Formula 到 Tap 仓库..."
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
cd ..

echo "✅ 完成发布！"
echo ""
echo "🍺 安装命令："
echo "  brew tap zk3151463/icon_logo"
echo "  brew install icon_logo"
echo ""
