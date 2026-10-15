from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageChops
import math, sys
S=4096; c=S/2
OUT=sys.argv[1]
FONT=__import__('os').path.join(__import__('os').path.dirname(__file__),'..','NeverLate','Fonts','ChakraPetch-Bold.ttf')
bg=(10,10,12); red=(128,24,38); red_hi=(150,34,48); blue=(22,40,82); blue_hi=(32,54,104)
gilt=(214,186,128); cream=(238,226,196); steel=(196,200,204); steel_dk=(110,114,120); black=(8,8,9)
lume_glow=(255,236,190)
img=Image.new('RGB',(S,S),bg); d=ImageDraw.Draw(img)
def pt(a,r): return (c+r*math.sin(a), c-r*math.cos(a))
def circ(dr,r,**k): dr.ellipse([c-r,c-r,c+r,c+r],**k)
def ring(dr,a0,a1,r0,r1,fill,n=200):
    pts=[pt(a0+(a1-a0)*i/n,r1) for i in range(n+1)]+[pt(a1-(a1-a0)*i/n,r0) for i in range(n+1)]
    dr.polygon(pts,fill=fill)
R=S*0.455
# steel case edge with knurl
circ(d,R,fill=steel_dk)
for i in range(180):
    a=i/180*2*math.pi
    d.line([pt(a,R*0.965),pt(a,R)],fill=steel,width=10)
circ(d,R*0.965,fill=steel)
bo=R*0.95; bi=R*0.74; bm=(bo+bi)/2; bw=bo-bi
# Pepsi insert: burgundy top half (18h..6h through 24), blue bottom
ring(d,-math.pi/2,math.pi/2,bi,bo,red)
ring(d,math.pi/2,3*math.pi/2,bi,bo,blue)
# subtle sheen on insert
sheen=Image.new('L',(S,S),0); sd=ImageDraw.Draw(sheen)
ring(sd,-math.pi*0.42,-math.pi*0.05,bi,bo,60)
sheen=sheen.filter(ImageFilter.GaussianBlur(60))
img=Image.composite(Image.new('RGB',(S,S),(255,255,255)),img,sheen.point(lambda v:int(v*0.35))); d=ImageDraw.Draw(img)
# 24h scale
font=ImageFont.truetype(FONT,int(bw*0.46))
for h in range(24):
    a=h/24*2*math.pi
    if h==0:
        tri=[pt(a,bi+bw*0.16),pt(a-0.085,bo-bw*0.14),pt(a+0.085,bo-bw*0.14)]
        d.polygon(tri,fill=gilt)
    elif h%2==0:
        txt=str(h); x,y=pt(a,bm)
        # rotate text tangentially
        tw=int(bw*1.2); t=Image.new('L',(tw,tw),0); td=ImageDraw.Draw(t)
        td.text((tw/2,tw/2),txt,font=font,fill=255,anchor='mm')
        rot=-math.degrees(a)
        if math.pi/2-1e-6<a<3*math.pi/2-1e-6: rot+=180
        t=t.rotate(rot,resample=Image.BICUBIC)
        img.paste(Image.new('RGB',(tw,tw),gilt),(int(x-tw/2),int(y-tw/2)),t)
    else:
        x,y=pt(a,bm); r=bw*0.07; d.ellipse([x-r,y-r,x+r,y+r],fill=gilt)
d=ImageDraw.Draw(img)
circ(d,bi,fill=(30,30,32))
# dial
dR=bi*0.97
dial=Image.new('RGB',(S,S),black); dd=ImageDraw.Draw(dial)
mask=Image.new('L',(S,S),0); ImageDraw.Draw(mask).ellipse([c-dR,c-dR,c+dR,c+dR],fill=255)
# soft dome highlight
hl=Image.new('L',(S,S),0); ImageDraw.Draw(hl).ellipse([c-dR*0.7,c-dR*0.95,c+dR*0.5,c-dR*0.1],fill=40)
hl=hl.filter(ImageFilter.GaussianBlur(220))
dial=Image.composite(Image.new('RGB',(S,S),(40,40,44)),dial,hl)
img.paste(dial,(0,0),mask); d=ImageDraw.Draw(img)
# minute track
for i in range(60):
    a=i/60*2*math.pi
    l=dR*(0.06 if i%5==0 else 0.035)
    d.line([pt(a,dR*0.985),pt(a,dR*0.985-l)],fill=(205,205,205) if i%5 else cream,width=10 if i%5 else 14)
# lume markers: dots w/ gilt surround, batons 3/6/9, triangle 12
def lume_shape(draw, h, fill, grow=0):
    a=h/12*2*math.pi
    if h==0:
        draw.polygon([pt(0,dR*0.66-grow),pt(-0.105-grow/dR*0.3,dR*0.89+grow),pt(0.105+grow/dR*0.3,dR*0.89+grow)],fill=fill)
    elif h in (3,6,9):
        p0=pt(a,dR*0.68-grow); p1=pt(a,dR*0.89+grow)
        draw.line([p0,p1],fill=fill,width=int(dR*0.085+grow*2))
    else:
        x,y=pt(a,dR*0.8); r=dR*0.07+grow; draw.ellipse([x-r,y-r,x+r,y+r],fill=fill)
glow=Image.new('RGB',(S,S),(0,0,0)); gd=ImageDraw.Draw(glow)
for h in range(12): lume_shape(gd,h,(120,110,80),grow=10)
glow=glow.filter(ImageFilter.GaussianBlur(30))
img=ImageChops.add(img,glow); d=ImageDraw.Draw(img)
for h in range(12): lume_shape(d,h,gilt,grow=14)
for h in range(12): lume_shape(d,h,cream)
# game target: glowing lume arc on bezel at ~ 2 o'clock (minute hand lands in it)
ta=math.radians(62); hw=0.2
g2=Image.new('RGB',(S,S),(0,0,0)); g2d=ImageDraw.Draw(g2)
ring(g2d,ta-hw,ta+hw,bi+bw*0.06,bo-bw*0.06,lume_glow)
g2=g2.filter(ImageFilter.GaussianBlur(70))
img=ImageChops.add(img,g2.point(lambda v:int(v*0.8))); d=ImageDraw.Draw(img)
ring(d,ta-hw,ta+hw,bi+bw*0.06,bo-bw*0.06,(232,214,170))
ring(d,ta-hw*0.35,ta+hw*0.35,bi+bw*0.06,bo-bw*0.06,(255,248,226))
# hands
def hand_shadow():
    pass
# hour hand at ~10 with square lume box (snowflake nod)
ha=math.radians(-58)
def poly_along(a,pts):
    # pts in (x along radius, y perpendicular)
    s,co=math.sin(a),math.cos(a)
    return [(c+r*s+w*co, c-r*co+w*s) for r,w in pts]
hw_=dR*0.035
d.polygon(poly_along(ha,[(-dR*0.12,-hw_),(dR*0.36,-hw_),(dR*0.36,hw_),(-dR*0.12,hw_)]),fill=steel)
box=dR*0.085
d.polygon(poly_along(ha,[(dR*0.36,-box),(dR*0.52,-box),(dR*0.52,box),(dR*0.36,box)]),fill=steel)
d.polygon(poly_along(ha,[(dR*0.375,-box*0.78),(dR*0.505,-box*0.78),(dR*0.505,box*0.78),(dR*0.375,box*0.78)]),fill=cream)
d.polygon(poly_along(ha,[(dR*0.52,-hw_),(dR*0.6,0),(dR*0.52,hw_)]),fill=steel)
# GMT hand: burgundy arrow pointing to ~ 7 o'clock
ga=math.radians(212)
d.line([pt(ga+math.pi,dR*0.1),pt(ga,dR*0.8)],fill=red_hi,width=int(dR*0.025))
d.polygon(poly_along(ga,[(dR*0.76,-dR*0.075),(dR*0.93,0),(dR*0.76,dR*0.075)]),fill=red_hi)
d.polygon(poly_along(ga,[(dR*0.785,-dR*0.045),(dR*0.88,0),(dR*0.785,dR*0.045)]),fill=cream)
# minute hand: long pencil into the target
ma=ta
mw=dR*0.03
d.polygon(poly_along(ma,[(-dR*0.14,-mw),(dR*0.82,-mw),(dR*0.9,0),(dR*0.82,mw),(-dR*0.14,mw)]),fill=steel)
d.polygon(poly_along(ma,[(dR*0.3,-mw*0.55),(dR*0.8,-mw*0.55),(dR*0.86,0),(dR*0.8,mw*0.55),(dR*0.3,mw*0.55)]),fill=cream)
# center cap
circ(d,dR*0.06,fill=steel); circ(d,dR*0.025,fill=steel_dk)
img=img.resize((1024,1024),Image.LANCZOS)
img.save(OUT)
