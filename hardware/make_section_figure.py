#!/usr/bin/env python3
"""生成 docs/images/camera_mount_80_section.png（一颗 M2 的剖面 + 沿轴叠图）。

数值是 camera_mount.scad v4（standoff_h=1.0、board_t=1.5）的手写常量：
立板 6.0、螺母槽 -4.05~-6.0（对边 4.3）、过孔 Ø2.4、立柱 0~1.0（Ø6.5 / 内孔 Ø2.8）、
PCB 1.0~2.5、螺钉头 2.5~4.0（Ø3.8）、杆 Ø2.0 到 -5.5。改设计时这里要跟着改。
只依赖 Pillow + Noto Sans CJK。
"""

import math
from PIL import Image, ImageDraw, ImageFont
SS=2; W,H=1600,1080
FONT="/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc"
def f(sz): return ImageFont.truetype(FONT,int(sz*SS))
img=Image.new("RGB",(W*SS,H*SS),(250,248,240)); d=ImageDraw.Draw(img)
PLASTIC=(208,168,52); PLASTIC_H=(170,134,36); PCB=(46,125,50); PCB_H=(26,90,30)
STEEL=(154,163,173); STEEL_H=(112,122,134); AIR=(250,248,240); NUT=(168,116,62)
S=58.0; X0,Y0=130,205; YMIN,ZMAX=-7.4,41.2
def X(y): return (X0+(y-YMIN)*S)*SS
def Y(z): return (Y0+(ZMAX-z)*S)*SS
def R(a,b,c,e): return [X(a),Y(e),X(b),Y(c)]
def hatch(rect,color,step=9,angle=45,w=1):
    x0,y0,x1,y1=[int(v) for v in rect]; ww,hh=x1-x0,y1-y0
    if ww<=0 or hh<=0: return
    lay=Image.new("RGBA",(ww,hh),(0,0,0,0)); dl=ImageDraw.Draw(lay); st=max(2,int(step*SS))
    for c in range(-hh,ww,st):
        if angle==45: dl.line([(c,hh),(c+hh,0)],fill=color,width=w*SS)
        else:         dl.line([(c,0),(c+hh,hh)],fill=color,width=w*SS)
    img.paste(lay,(x0,y0),lay)
def part(a,b,c,e,fill,hc,step=9,cross=False):
    r=R(a,b,c,e); d.rectangle(r,fill=fill)
    if cross: hatch(r,hc,step,45); hatch(r,hc,step,-45)
    else: hatch(r,hc,step,45)
    d.rectangle(r,outline=(60,50,30),width=max(1,int(1.1*SS)))
ZB,ZT=32.2,41.2
part(-6.0,0.0,ZB,ZT,PLASTIC,PLASTIC_H,step=8)
d.rectangle(R(-6.0,-4.05,34.35,38.65),fill=AIR)
d.rectangle(R(-4.05,0.0,35.3,37.7),fill=AIR)
part(-6.0,-4.40,34.35,38.65,NUT,(118,76,38),step=7)
part(1.0,2.5,ZB,ZT,PCB,PCB_H,step=7,cross=True)
d.rectangle(R(1.0,2.5,35.35,37.65),fill=AIR)
part(0.0,1.0,33.25,35.1,PLASTIC,PLASTIC_H,step=6)
part(0.0,1.0,37.9,39.75,PLASTIC,PLASTIC_H,step=6)
part(-5.5,4.0,35.5,37.5,STEEL,STEEL_H,step=8)
part(2.5,4.0,34.6,38.4,STEEL,STEEL_H,step=8)
for zz in (35.9,36.5,37.1):
    d.line([X(-5.95),Y(zz),X(-4.45),Y(zz)],fill=(92,56,30),width=int(1.1*SS))
# 标题
d.text((X0*SS,30*SS),"一颗螺丝的剖面（沿螺丝轴线切开；单位 mm，横竖同比例）",font=f(29),fill=(40,35,25))
d.text((X0*SS,80*SS),"右边 = 镜头那一面（正面，朝外）；左边 = 背面（螺母埋在立板里）。看这个剖面时，光是从右边照进来的。",font=f(19),fill=(95,85,62))
d.text((X0*SS,108*SS),"灰 = 钢（M2×8 螺丝 + 六角螺母）　绿 = PCB　土黄 = 打印件（PLA，斜线表示实心）　纯白 = 空气",font=f(19),fill=(95,85,62))
d.text((X(-5.6),Y(40.85)-64*SS),"拧紧时：螺钉头往左压、螺母往右兜，中间 5 层被夹死",font=f(18),fill=(170,45,35))
za=40.85
d.line([X(-5.6),Y(za),X(3.7),Y(za)],fill=(255,255,255),width=int(5*SS))
d.line([X(-5.6),Y(za),X(3.7),Y(za)],fill=(200,60,45),width=int(2*SS))
for xx,sgn in ((X(-5.6),1),(X(3.7),-1)):
    d.polygon([(xx,Y(za)),(xx+sgn*12*SS,Y(za)-7*SS),(xx+sgn*12*SS,Y(za)+7*SS)],fill=(200,60,45))
# 尺寸链
dy=Y(ZB)+46*SS
for a,b,t in [(-6.0,-4.4,"1.6"),(-4.4,-4.05,"0.35"),(-4.05,0.0,"4.05"),(0.0,1.0,"1.0"),(1.0,2.5,"1.5"),(2.5,4.0,"1.5")]:
    d.line([X(a),dy,X(b),dy],fill=(70,60,40),width=int(1.1*SS))
    for xx in (X(a),X(b)): d.line([xx,dy-6*SS,xx,dy+6*SS],fill=(70,60,40),width=int(1.1*SS))
    d.text(((X(a)+X(b))/2-11*SS,dy+10*SS),t,font=f(17),fill=(70,60,40))
d.text((X(-6.0),dy-26*SS),"M2×8 吃牙 1.45 / 1.6（螺母厚 1.6），尖端停在槽里、不出背面",font=f(17),fill=(170,45,35))
# 编号
def tag(y,z,n):
    cx,cy=X(y),Y(z); r=15*SS
    d.ellipse([cx-r,cy-r,cx+r,cy+r],fill=(252,252,252),outline=(40,40,40),width=int(1.5*SS))
    tw=d.textlength(str(n),font=f(18)); d.text((cx-tw/2,cy-10*SS),str(n),font=f(18),fill=(20,20,20))
tag(3.25,36.5,1); tag(1.75,33.6,2); tag(0.5,34.2,3); tag(-2.4,40.0,4); tag(-5.2,34.9,5)
# 图例
leg=[("1","M2 螺钉头 Ø3.8：压在 PCB 正面。整条链里没有任何塑料螺纹，力是「夹」出来的。"),
     ("2","PCB 1.5（实测 1.45–1.55）：螺丝从板上 Ø2.3 的孔穿过，头和板之间不垫东西。"),
     ("3","立柱环 Ø6.5、内孔 Ø2.8：PCB 背面只压在这圈 1.75 mm 宽的实心环上；中间 1.0 mm 是空的，只走螺丝。"),
     ("4","立板 6.0：中间的 Ø2.4 是 X 向长圆孔（±0.6），用来吃 13.0–13.6 的孔距公差，不是螺纹。"),
     ("5","M2 六角螺母：塞在背面「对边 4.3、深 1.9」的六角槽里；槽是通的，换螺丝不用拆支架。")]
ly=Y(ZB)+100*SS
for n,t in leg:
    d.ellipse([X0*SS,ly,(X0+21)*SS,ly+21*SS],fill=(252,252,252),outline=(40,40,40),width=int(1.3*SS))
    tw=d.textlength(n,font=f(15)); d.text((X0*SS+10.5*SS-tw/2,ly+3*SS),n,font=f(15),fill=(20,20,20))
    d.text(((X0+31)*SS,ly+1*SS),t,font=f(18),fill=(50,45,35)); ly+=30*SS
# 右栏
bx=1010
d.rectangle([bx*SS,165*SS,(bx+520)*SS,585*SS],outline=(200,190,165),width=int(1.4*SS),fill=(245,242,232))
d.text((bx*SS+18*SS,178*SS),"这张图到底在说什么",font=f(23),fill=(40,35,25))
lines=[("b","装上去是这样的："),("n","螺丝从镜头那一面穿进去 → 穿过 PCB 的 Ø2.3 孔 →"),
 ("n","穿过 1.0 mm 的架空 → 穿过立板里的 Ø2.4 长圆孔 →"),("n","最后拧进背面六角槽里的螺母。"),
 ("b","为什么能夹住："),("n","PCB 的背面不是悬空的，它压在 4 个 Ø6.5 立柱顶上的"),
 ("n","环形面上（图中 ③）。拧紧时螺钉头往里压、螺母往外兜，"),("n","板就被「环」和「头」夹死，两镜头才不会动。"),
 ("b","最容易看错的一点："),("n","立板里那个孔是 Ø2.4 的长圆孔，比螺丝粗、还长 3.6 mm。"),
 ("n","如果 PCB 直接贴在立板上，螺钉头压住的那圈正好落在孔上，"),("n","一拧板就陷。所以立柱把板抬开 1.0 mm，让压力落在实心环上。")]
yy=232
for k,t in lines:
    d.text((bx*SS+18*SS,yy*SS),t,font=f(19 if k=="n" else 20),fill=(45,40,30) if k=="n" else (25,70,110)); yy+=28
# 俯视小图
P=22.0; CX,CY=1085,706
def px(mm): return mm*P*SS
d.rectangle([bx*SS,600*SS,(bx+520)*SS,800*SS],outline=(200,190,165),width=int(1.4*SS),fill=(245,242,232))
d.text(((bx+18)*SS,610*SS),"沿螺丝轴线看过去：立板上的孔 vs 立柱环的范围（叠图）",font=f(18),fill=(25,70,110))
ro=3.25*P*SS; cx=CX*SS; cy=CY*SS
d.ellipse([cx-ro,cy-ro,cx+ro,cy+ro],fill=PLASTIC)
mw=int(2*ro); mimg=Image.new("RGBA",(mw,mw),(0,0,0,0)); md=ImageDraw.Draw(mimg)
md.ellipse([0,0,mw-1,mw-1],fill=(255,255,255,255))
lay=Image.new("RGBA",(mw,mw),(0,0,0,0)); dl=ImageDraw.Draw(lay)
for c in range(-mw,mw,int(8*SS)): dl.line([(c,mw),(c+mw,0)],fill=PLASTIC_H,width=1*SS)
mimg2=Image.new("RGBA",(mw,mw),(0,0,0,0)); mimg2.paste(lay,(0,0),mimg)
img.paste(mimg2,(int(cx-ro),int(cy-ro)),mimg2)
d=ImageDraw.Draw(img)
d.ellipse([cx-ro,cy-ro,cx+ro,cy+ro],outline=(60,50,30),width=int(1.8*SS))
d.rounded_rectangle([(CX-1.8*P)*SS,(CY-1.2*P)*SS,(CX+1.8*P)*SS,(CY+1.2*P)*SS],radius=1.2*P*SS,fill=(253,252,247),outline=(120,85,50),width=int(1.8*SS))
for i in range(0,40,2):
    a0=2*math.pi*i/40; a1=2*math.pi*(i+1)/40
    d.line([CX*SS+1.15*P*SS*math.cos(a0),CY*SS-1.15*P*SS*math.sin(a0),CX*SS+1.15*P*SS*math.cos(a1),CY*SS-1.15*P*SS*math.sin(a1)],fill=(20,110,40),width=int(1.5*SS))

yy=632
labs=[((208,168,52),"立柱环 Ø6.5 的范围（PLA 实心）：比孔大，整个盖得住"),
      ((120,85,50),"3.6×2.4 长圆孔（立板里挖空的，螺丝有 ±0.6 余量）"),
      ((20,110,40),"Ø2.3 PCB 过孔（虚线），螺丝从中心穿过")]
for col,t in labs:
    d.rectangle([(bx+150)*SS,yy*SS,(bx+162)*SS,(yy+12)*SS],fill=col,outline=(80,70,50),width=int(1.0*SS))
    d.text(((bx+168)*SS,(yy-1)*SS),t,font=f(14),fill=(50,45,35)); yy+=26
img=img.resize((W,H),Image.LANCZOS)
import os
out=os.path.join(os.path.dirname(os.path.abspath(__file__)),"..","docs","images","camera_mount_80_section.png")
img.save(out); print("ok",img.size)