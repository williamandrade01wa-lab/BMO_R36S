import struct
class Ext:
 def __init__(self,p):
  self.f=p.open("rb");self.off=0
  m=self.r(0,512);self.start=struct.unpack_from("<I",m,462+8)[0]*512;self.off=self.start
  self.sb=self.r(1024,1024);s=self.sb
  assert struct.unpack_from("<H",s,56)[0]==0xef53
  self.bs=1024<<struct.unpack_from("<I",s,24)[0];self.ipg=struct.unpack_from("<I",s,40)[0]
  self.isz=struct.unpack_from("<H",s,88)[0];self.ds=max(32,struct.unpack_from("<H",s,254)[0])
  self.first=struct.unpack_from("<I",s,20)[0]
 def r(self,o,n):
  self.f.seek(self.off+o);b=self.f.read(n)
  if len(b)!=n:raise RuntimeError("Not extracted yet at "+str(self.off+o+n))
  return b
 def inode(self,n):
  g,j=divmod(n-1,self.ipg);d=self.r((self.first+1)*self.bs+g*self.ds,self.ds)
  tab=struct.unpack_from("<I",d,8)[0]
  if self.ds>=64:tab|=struct.unpack_from("<I",d,40)[0]<<32
  return self.r(tab*self.bs+j*self.isz,self.isz)
 def size(self,i):return struct.unpack_from("<I",i,4)[0]+(struct.unpack_from("<I",i,108)[0]<<32)
 def extents(self,tree):
  magic,entries,_,depth=struct.unpack_from("<HHHH",tree,0);assert magic==0xf30a
  result=[]
  for k in range(entries):
   a,b,c,d=struct.unpack_from("<IHHI",tree,12+k*12)
   if depth:
    leaf=struct.unpack_from("<I",tree,16+k*12)[0]+(struct.unpack_from("<H",tree,20+k*12)[0]<<32)
    result.extend(self.extents(self.r(leaf*self.bs,self.bs)))
   else:result.append((a,b&0x7fff,(c<<32)+d))
  return sorted(result)
 def data(self,i):
  size=self.size(i);mode=struct.unpack_from("<H",i)[0]
  if mode&0xf000==0xa000 and size<=60:return i[40:40+size]
  assert struct.unpack_from("<I",i,32)[0]&0x80000
  b=bytearray(size)
  for logical,count,physical in self.extents(i[40:100]):
   start=logical*self.bs;end=min(size,start+count*self.bs)
   if start<size:b[start:end]=self.r(physical*self.bs,end-start)
  return bytes(b)
 def dirs(self,n):
  b=self.data(self.inode(n));out={};o=0
  while o+8<=len(b):
   ino,reclen,namelen,ft=struct.unpack_from("<IHBB",b,o)
   if not reclen:break
   if ino:out[b[o+8:o+8+namelen].decode("utf8",errors="replace")]=(ino,ft)
   o+=reclen
  return out
 def resolve(self,path):
  n=2
  for part in path.strip("/").split("/"):
   if part:n=self.dirs(n)[part][0]
  return n
