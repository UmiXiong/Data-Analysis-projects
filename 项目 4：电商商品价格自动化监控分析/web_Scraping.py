import random

from bs4 import BeautifulSoup
# smtplib为邮件库
import requests,smtplib,time,datetime

# 链接到网站

# URL = 'https://www.amazon.com/gp/product/B088WP2FWQ/ref=ox_sc_act_image_1?smid=AGHFGR4RK7H18&th=1&psc=1'
#
# headers = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.108 Safari/537.36", "Accept-Encoding":"gzip, deflate", "Accept":"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", "DNT":"1","Connection":"close", "Upgrade-Insecure-Requests":"1"}
#
# # 获取页面
# page=requests.get(URL,headers=headers)
# print(page)
#
# # 页面返回格式
# soup1=BeautifulSoup(page.content,"html.parser")
# # pretrtify: 更加符合格式
# soup2=BeautifulSoup(soup1.prettify(),"html.parser")
# # print("soup1:")
# # print(soup1)
# #
# # print("soup2:")
# # print(soup2)
#
# # 查找标题
# print("title")
# title=soup2.find(id='productTitle').get_text().strip()
# print(title)
#
# # 查找价格：使用id查找（没找到）
# # price=soup2.find
# # price = soup2.find(id='priceblock_ourprice').get_text()
# # print(price)
# price=16.99
# today=datetime.date.today()
#
import csv
# header=['Title','Price','date']
# data=[title,price,today]
#
#
# # 创建csv文件:w表示写，a+表示添加
# with open("project_scraping.csv",'w') as f:
#     writer=csv.writer(f)
#     writer.writerow(header)
#     writer.writerow(data)


#     查看表格内容
import pandas as pd

df=pd.read_csv("project_scraping.csv")
print(df)


def send_mail():
    server=smtplib.SMTP_SSL("smtp.163.com",465)
    server.ehlo()
    server.login("18519644256@163.com","PFcGj9uhwfnLGA9T")
    subject="This product is lower tha $15"
    body="now is time to buy it"
    msg=f"Subject:{subject}\n\n{body}"
    print("here it is")
    server.sendmail("18519644256@163.com","18519644256@163.com",msg)

#


# 定时显示
def check_price():
    URL = 'https://www.amazon.com/gp/product/B088WP2FWQ/ref=ox_sc_act_image_1?smid=AGHFGR4RK7H18&th=1&psc=1'
    headers = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.108 Safari/537.36", "Accept-Encoding":"gzip, deflate", "Accept":"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", "DNT":"1","Connection":"close", "Upgrade-Insecure-Requests":"1"}
    page=requests.get(URL,headers=headers)
    soup1=BeautifulSoup(page.content,"html.parser")
    soup2=BeautifulSoup(soup1.prettify(),"html.parser")

    title=soup2.find(id='productTitle').get_text().strip()
    price=random.randint(10,20)
    print("price:"+str(price))
    today=datetime.date.today()

    header=['Title','Price','date']
    data=[title,price,today]
    if price<15:
        # 发送邮件
        send_mail()
        print("send it")

    # a+表示内容追加
    with open("project_scraping.csv",'a+') as f:
        writer=csv.writer(f)
        writer.writerow(data)


while(True):
    try:
        check_price()
    except:
        continue

    # time.sleep(2)
    print("test")























