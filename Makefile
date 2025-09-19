ARCHS = arm64
TARGET = iphone:clang:latest:15.0

# Rootless 插件配置
export THEOS_PACKAGE_SCHEME = rootless
THEOS_PACKAGE_INSTALL_PREFIX = /var/jb

# 目标进程
INSTALL_TARGET_PROCESSES = WeChat

include $(THEOS)/makefiles/common.mk

# Tweak定义
TWEAK_NAME = WeChat

# 核心源文件
WeChat_FILES = Tweak.xm \
               WCPulseLoader.m \
               SpeedFloatView.m \
               Config.m \
               CustomGroupVC.m \
               FloatingTagView.m \
               FloatingTagCell.m \
               GroupSettingViewController.m \
               SessionInfo.m \
               MainLayoutManager.m \
               SessionMgr.m \
               DataManager.m \
               Loader.m

# Masonry 自动布局库
WeChat_FILES += masonry/MASCompositeConstraint.m \
                masonry/MASConstraint.m \
                masonry/MASConstraintMaker.m \
                masonry/MASLayoutConstraint.m \
                masonry/MASViewAttribute.m \
                masonry/MASViewConstraint.m \
                masonry/NSArray+MASAdditions.m \
                masonry/NSLayoutConstraint+MASDebugAdditions.m \
                masonry/View+MASAdditions.m \
                masonry/ViewController+MASAdditions.m

# JazzHands 动画库
WeChat_FILES += jazzhands/IFTTTAlphaAnimation.m \
                jazzhands/IFTTTAnimatedPagingScrollViewController.m \
                jazzhands/IFTTTAnimatedScrollViewController.m \
                jazzhands/IFTTTAnimation.m \
                jazzhands/IFTTTAnimator.m \
                jazzhands/IFTTTBackgroundColorAnimation.m \
                jazzhands/IFTTTConstraintConstantAnimation.m \
                jazzhands/IFTTTConstraintMultiplierAnimation.m \
                jazzhands/IFTTTCornerRadiusAnimation.m \
                jazzhands/IFTTTEasingFunction.m \
                jazzhands/IFTTTFilmstrip.m \
                jazzhands/IFTTTFrameAnimation.m \
                jazzhands/IFTTTHideAnimation.m \
                jazzhands/IFTTTInterpolatable.m \
                jazzhands/IFTTTLayerFillColorAnimation.m \
                jazzhands/IFTTTLayerStrokeEndAnimation.m \
                jazzhands/IFTTTLayerStrokeStartAnimation.m \
                jazzhands/IFTTTMaskAnimation.m \
                jazzhands/IFTTTPathPositionAnimation.m \
                jazzhands/IFTTTRotationAnimation.m \
                jazzhands/IFTTTScaleAnimation.m \
                jazzhands/IFTTTScrollViewPageConstraintAnimation.m \
                jazzhands/IFTTTShapeLayerAnimation.m \
                jazzhands/IFTTTTextColorAnimation.m \
                jazzhands/IFTTTTransform3DAnimation.m \
                jazzhands/IFTTTTranslationAnimation.m \
                jazzhands/IFTTTViewAnimation.m \
                jazzhands/UIView+IFTTTJazzHands.m

# FXBlurView 模糊效果库
WeChat_FILES += fxblurview/FXBlurView.m

# FMDB 数据库库
WeChat_FILES += fmdb/FMDatabase.m \
                fmdb/FMDatabaseAdditions.m \
                fmdb/FMDatabasePool.m \
                fmdb/FMDatabaseQueue.m \
                fmdb/FMResultSet.m

# Pop 动画库 (Facebook)
WeChat_FILES += pop/POPAnimatableProperty.mm \
                pop/POPAnimation.mm \
                pop/POPAnimationEvent.mm \
                pop/POPAnimationExtras.mm \
                pop/POPAnimationRuntime.mm \
                pop/POPAnimationTracer.mm \
                pop/POPAnimator.mm \
                pop/POPBasicAnimation.mm \
                pop/POPCGUtils.mm \
                pop/POPCustomAnimation.mm \
                pop/POPDecayAnimation.mm \
                pop/POPGeometry.mm \
                pop/POPLayerExtras.mm \
                pop/POPMath.mm \
                pop/POPPropertyAnimation.mm \
                pop/POPSpringAnimation.mm \
                pop/POPVector.mm \
                pop/WebCore/TransformationMatrix.cpp

# 系统框架
WeChat_FRAMEWORKS = UIKit Foundation CoreGraphics QuartzCore
WeChat_PRIVATE_FRAMEWORKS = 

# 库依赖
WeChat_LIBRARIES = substrate sqlite3

# 编译标志
WeChat_CFLAGS = -fobjc-arc \
                -fmodules \
                -fcxx-modules \
                -Wno-deprecated-declarations \
                -Wno-vla-cxx-extension \
                -Wno-missing-noescape \
                -Wno-objc-dictionary-duplicate-keys \
                -Wno-unused-variable \
                -Wno-unused-function \
                -Wno-incompatible-pointer-types \
                -Wno-implicit-function-declaration \
                -I$(CURDIR) \
                -I$(CURDIR)/pop \
                -I$(CURDIR)/pop/WebCore \
                -I$(CURDIR)/masonry \
                -I$(CURDIR)/jazzhands \
                -I$(CURDIR)/fxblurview \
                -I$(CURDIR)/fmdb

# C++ 编译标志
WeChat_CXXFLAGS = $(WeChat_CFLAGS) \
                  -std=c++11 \
                  -stdlib=libc++

# 链接标志
WeChat_LDFLAGS = -ObjC \
                 -Qunused-arguments

include $(THEOS_MAKE_PATH)/tweak.mk
