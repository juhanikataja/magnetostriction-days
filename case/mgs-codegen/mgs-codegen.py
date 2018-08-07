
# coding: utf-8

# In[1]:

from IPython.core.display import HTML
HTML("<style>.container { width:100% !important; }</style>")

import sympy as sp
from sympy import pi, var, symbols, Matrix, trace, diff, eye, pprint

symbolic_nu = False

# In[2]:

all_models =["icems_latest", "big_model", "small_model", "modelname"]

model = "modelname" # "big_model", "small_model"

if model=="modelname":
  nalfa = 8; nbeta = 4; ngamma = 3;
  par0_8_4_3=[-0.374926,-103.579085,271.650037,-284.468890,145.603954,
      -26.235203,-3.363513,1.332486,-0.102024,-1.794344,-1.421124,
      -1288.845594,1.162565,1.260278,57.605174]
  alfa = par0_8_4_3[0:nalfa]
  beta = par0_8_4_3[nalfa:nalfa+nbeta]
  gamma = par0_8_4_3[nalfa+nbeta:nalfa+nbeta+ngamma]

if model == "icems_latest":
  nalfa = 8; nbeta = 4; ngamma = 3;
  par0_8_4_3=[ 0.034370, 0.002555, 0.100791, -0.227696, 0.267234, 
      -0.165990, 0.052627, -0.006126, -0.620893, 8.338901, 145.565467,
      -1729.351674, 1.689967, -9.834233, 16.875844]
  alfa = par0_8_4_3[0:nalfa]
  beta = par0_8_4_3[nalfa:nalfa+nbeta]
  gamma = par0_8_4_3[nalfa+nbeta:nalfa+nbeta+ngamma]

if model=="big_model":
  nalfa = 8; nbeta = 4; ngamma = 3;
  par0_8_4_3=[-0.374926,-103.579085,271.650037,-284.468890,145.603954,
      -26.235203,-3.363513,1.332486,-0.102024,-1.794344,-1.421124,
      -1288.845594,1.162565,1.260278,57.605174]
  alfa = par0_8_4_3[0:nalfa]
  beta = par0_8_4_3[nalfa:nalfa+nbeta]
  gamma = par0_8_4_3[nalfa+nbeta:nalfa+nbeta+ngamma]

if model=="small_model":
  nalfa = 8; nbeta=1; ngamma = 1;
  par0_8_1_1 = [-0.374936,-58.019802,87.156990, 48.789107, -153.189509, 114.994421, -37.144889, 4.548709, -0.030705, 1.215842]
  alfa = par0_8_1_1[0:nalfa]
  beta = par0_8_1_1[nalfa:nalfa+nbeta]
  gamma = par0_8_1_1[nalfa+nbeta:nalfa+nbeta+ngamma]

if not model in all_models:
    raise ValueError("Unknown model > "+model+" <")
else:
    print("Using model > "+model+" <")


mu0 = 4e-7*pi

if symbolic_nu:
    nu0 = symbols('nu_0',real=True)
else:
    nu0 = 1/mu0


# In[3]:

var('exx eyy ezz exy eyx exz ezx eyz ezy r Bx By Bz', real=True)
E, nu = symbols('E_me nu_me', real=True)


# In[4]:

def gf(ii,I1,nu0):
    A0 = -nu0/8*-3*1
    #cc = [4.0*(i+1.0)/3.0 for i in ii]
    cc = [4*(i+1) for i in ii]
    g = [alfa[i]*(1+I1*cc[i]/3) for i in ii]
    g[0] = nu0*g[0] + A0
    gd = [cc[i]*alfa[i]*(1+I1*cc[i]/3)/3 for i in ii]
    gd[0] = gd[0]*nu0
    return Matrix(g),Matrix(gd)


# In[5]:

lam = E*nu/((1+nu)*(1-2*nu))
G   = E/(2*(1+nu))


# In[6]:

B1, B2, B3, Babs = symbols('B1:4 |B|')
g0,g1,g2,g3,g4 = symbols('g0:5')
(exx,exy,exz,eyx,eyy,eyz,ezx,ezy,ezz) = symbols('e1:4(1:4)')
B = Matrix([B1,B2,B3])
epst = Matrix([[exx,exy,exz],[eyx,eyy,eyz],[ezx,ezy,ezz]])


# In[7]:

epstd = epst-trace(epst)/3*eye(3)


# In[8]:

I1 = trace(epst)
I2 = 0.5*trace(epst*epst)
I4 = sum(B.T*B)
I5 = sum(B.T*epstd*B)
I6 = sum(B.T*epstd*epstd*B)
#I5 = 0
#I6 = 0


# In[9]:

d4dB = Matrix([diff(I4,B[i]) for i in [0,1,2]])
d5dB = Matrix([diff(I5,B[i]) for i in [0,1,2]])
d6dB = Matrix([diff(I6,B[i]) for i in [0,1,2]])
d5de = Matrix([[diff(I5,epst[i,j]) for j in [0,1,2]] for i in [0,1,2]])
d6de = Matrix([[diff(I6,epst[i,j]) for j in [0,1,2]] for i in [0,1,2]])


# In[10]:

psi5 = sum([nu0*beta[i]*pow(1e2*I5,i+1) for i in range(0,nbeta)])
psi6 = sum([1000*nu0*gamma[i]*pow(1e6*I6,i+1) for i in range(0,ngamma)])


# In[11]:

ii = Matrix(range(0,nalfa))
(g,dg) = gf(ii,I1,nu0)
I4pow0 = Matrix([pow(I4,i) for i in ii])
I4pow1 = Matrix([pow(I4,i+1) for i in ii])
psi4 = sum(g.T*I4pow0)
psit1 = sum([I4pow1[i]*dg[i]/(i+1) for i in range(0,nalfa)])
psi1 = lam*I1 + psit1;
psi2 = 2*G


# In[12]:

H = psi4*d4dB + psi5*d5dB + psi6*d6dB
M = nu0*B-H


# In[44]:

# Shorthand
BOB = B*B.T
BOM = B*M.T
BB = (B.T*B)[0]
MB = (M.T*B)[0]
E3 = eye(3)


HB = H.subs(exx,0).subs(eyy,0).subs(ezz,0).subs(exy,0).subs(eyx,0).subs(eyz,0).subs(ezy,0).subs(exz,0).subs(ezx,0)
#pprint(H.subs(B1**2+B2**2+B3**2,Bsq),num_columns=200)
#pprint(HB[0].subs(B1**2+B2**2+B3**2,Bsq),num_columns=200)

Hx,Hy,Hz,nu0s = symbols('H1:4,nu_0',real=True)
Hsym = Matrix([Hx,Hy,Hz])
M0 = nu0s*B-Hsym
Sme = psi1*eye(3) + psi2*epst+psi5*d5de+psi6*d6de
Smag = nu0*(BOB-0.5*BB*E3) + MB*E3-BOM
Smag0 = nu0s*(B*B.T-BB*E3/2) + (M0.T*B)[0]*E3-B*M0.T
S = Sme + Smag
#pprint(simplify(Smag0).subs(B1**2+B2**2+B3**2,Bsq),num_columns=220)
#print("S_me = ")
#pprint(Smag[0,0].subs(sqrt(B1**2+B2**2+B3**2),Babs).subs(exx,0).subs(eyy,0).subs(ezz,0),num_columns=200)
#print("H1 = ")
#pprint(H[0].subs(sqrt(B1**2+B2**2+B3**2),Babs).subs(B1**2+B2**2+B3**2,Bsq),num_columns=200)


# In[14]:

Hx = HB[0].subs(B2,0).subs(B3,0)
pprint(sp.sqrt(BB))
#pprint(simplify(Sme.subs(B1,0).subs(B2,0).subs(B3,0)))


# In[15]:

#from sympy.plotting import plot
#plot(Hx,(B1,0,1))


# In[16]:

from sympy.utilities.codegen import codegen


# 

# In[17]:

inds = [0,1,2]
dHdB=Matrix([[diff(H[m],B[n]) for n in [0,1,2]] for m in [0,1,2]])
dSde=Matrix([[diff(S[m1,n1],epst[m2,n2]) for n2 in inds for m2 in inds] for n1 in inds for m1 in inds])
dSdB=Matrix([[diff(S[m1,n1],B[k]) for k in inds] for n1 in inds for m1 in inds])
dHde=Matrix([[diff(H[k],epst[m,n]) for n in inds for m in inds] for k in inds])


# In[18]:

inds=[1,2,3]
ind_test=Matrix([[(m1,n1,m2,n2) for n2 in inds for m2 in inds] for n1 in inds for m1 in inds])
ind_test
Bsq,trE = symbols('B^2 Tr(e)',real=True)
pprint(S.subs(B1,0).subs(B2,0).subs(B3,0).subs(exx+eyy+ezz,trE),num_columns=200)
#pprint(S[0,0].subs(exx+eyy+ezz,trE).subs(B1**2+B2**2+B3**2,Bsq),num_columns=200)


# # Export Fortran code

# In[19]:

#[(HB_name,HB_code),HB_header] = 
codelist = [("mgs_HB",H),("mgs_Sme",Sme),("mgs_Smag",Smag),("mgs_S",S),("mgs_dHdB",dHdB),("mgs_dSde",dSde),("mgs_dHde",dHde),("mgs_HB_0",HB)]

map(lambda ll: codegen(ll,"F95",project="elmer-mgs",to_files=True), codelist)
#[(Sme_name,Sme_code),Sme_header] = 
#codegen(("Sme",Sme),"F95",to_files=True,project="elmer-mgs")


# In[20]:

B


# In[21]:

import sympy.printing as pri


# In[36]:

assert pri.jscode(S[0,0].subs(B1,0).subs(B2,0).subs(B3,0).subs(exx+eyy+ezz,trE)) == "E_me*Tr(e)*nu_me/((-2*nu_me + 1)*(nu_me + 1)) + 2*E_me*e11/(2*nu_me + 2)"


# # Collect HB curve

# In[37]:

import numpy as np
import matplotlib.pyplot as plt
HB_fun = lambda x: sp.N(HB[0].subs(B2,0).subs(B3,0).subs(B1,x).subs(exx,0).subs(eyy,0).subs(ezz,0).subs(nu0,1/mu0))

def sample_HB(maxB=1.9,numsamples=150):
    """
    Sapmle HB_fun from 0 to maxB using numsamples samples
    """
    B_samples = np.linspace(0,maxB,numsamples)
    HB_samples = [HB_fun(x) for x in B_samples]
    fig = plt.semilogy(B_samples, HB_samples)
    return B_samples, HB_samples, fig

B_samples, HB_samples, fig = sample_HB(2.5,200)
plt.show(fig)
plt.show(sample_HB(0.1,50)[2])

# In[39]:

pprint(HB_samples[49],num_columns=200)
pprint(HB_fun(3))


# In[40]:



# In[41]:

fname = "HB_"+str(nalfa)+"_"+str(nbeta)+"_"+str(ngamma)
ff=open(fname,'w')
out = [ff.write(str(B_samples[i]) + " " + str(HB_samples[i]) + "\n") for i in range(0,len(B_samples))]
ff.flush()


# In[42]:

S[0,0].subs(B1,1).subs(eyy,0).subs(ezz,0).subs(B2,0).subs(B3,0).subs(eyx,0).subs(exy,0).subs(exz,0).subs(ezx,0).subs(ezy,0).subs(eyz,0).subs(E,120e9).subs(nu,0.3)
S_nl = S[0,0].subs(B1,1e-1).subs(eyy,1e-6).subs(ezz,0).subs(B2,1).subs(B3,0).subs(eyx,0).subs(exy,0).subs(exz,0).subs(ezx,0).subs(ezy,0).subs(eyz,0).subs(E,120e9).subs(nu,0.3)
S_l = S[0,0].subs(B1,0).subs(eyy,1e-6).subs(ezz,0).subs(B2,1).subs(B3,0).subs(eyx,0).subs(exy,0).subs(exz,0).subs(ezx,0).subs(ezy,0).subs(eyz,0).subs(E,120e9).subs(nu,0.3)
#plot(log(H[0]).subs(exx,0).subs(eyy,0).subs(ezz,0).subs(B2,1).subs(B3,0).subs(eyx,0).subs(exy,0).subs(exz,0).subs(ezx,0).subs(ezy,0).subs(eyz,0).subs(E,120e9).subs(nu,0.3),(B1,0,1.9))


# In[43]:

# sp.plot((S_nl-S_l)/S_nl,(exx,0,1e-6))


# In[ ]:



