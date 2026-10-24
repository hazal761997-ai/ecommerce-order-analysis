"""
E-commerce Order Analysis - Customer & Basket Analytics (Python)
GOIT Data Analytics Hackathon | E-commerce Track

Klasor yapisi (script python/ klasorunde calisir):
    datathon2/
      data/    -> orders.csv, order_items.csv, products.csv, users.csv
      python/  -> rfm_analysis.py  (bu dosya)
      python/outputs/ -> grafikler ve csv ciktilari (otomatik olusur)

Calistirma:
    pip install pandas matplotlib seaborn
    python rfm_analysis.py
"""

from pathlib import Path
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

BASE = Path(__file__).resolve().parent.parent
DATA = BASE / "data"
OUT = Path(__file__).resolve().parent / "outputs"
OUT.mkdir(exist_ok=True)

sns.set_theme(style="whitegrid")


def read_table(name):
    """'orders.csv' veya 'orders (preview).csv' gibi dosyalari bulup okur."""
    matches = sorted(DATA.glob(f"{name}*.csv"))
    if not matches:
        raise FileNotFoundError(f"{name} icin csv bulunamadi: {DATA}")
    return pd.read_csv(matches[0])


# ------------------------------------------------------------------
# 4.1 Veriyi yukle ve birlestir
# ------------------------------------------------------------------
orders = read_table("orders")
items = read_table("order_items")
products = read_table("products")
users = read_table("users")

orders["order_date"] = pd.to_datetime(orders["order_date"])

print("Satir sayilari:",
      {"orders": len(orders), "order_items": len(items),
       "products": len(products), "users": len(users)})

# Duplicate kontrolu (anahtar alanlar)
print("Duplicate order_id:", orders["order_id"].duplicated().sum())
print("Duplicate user_id:", users["user_id"].duplicated().sum())
print("Duplicate product_id:", products["product_id"].duplicated().sum())

# Merge: order_items -> orders -> users, order_items -> products
df = (
    items
    .merge(orders, on="order_id", how="left", validate="m:1")
    .merge(products, on="product_id", how="left", validate="m:1")
    .merge(users, on="user_id", how="left", validate="m:1")
)

# Merge sonrasi kontroller
print("\nMerge sonrasi satir:", len(df), "| order_items satir:", len(items))
assert len(df) == len(items), "JOIN sonrasi satir cogalmasi var!"
print("NULL sayilari:\n", df.isna().sum()[df.isna().sum() > 0])

df["item_revenue"] = df["price"] * df["quantity"]
df["month"] = df["order_date"].dt.to_period("M").dt.to_timestamp()

# orders.total_amount ile kalem toplamlarinin uyumu
check = (df.groupby("order_id")["item_revenue"].sum()
         .rename("items_total").to_frame()
         .join(orders.set_index("order_id")["total_amount"]))
mismatch = (check["items_total"] - check["total_amount"]).abs() > 0.01
print(f"total_amount ile kalem toplami uyusmayan siparis: {mismatch.sum()}")

# ------------------------------------------------------------------
# 4.2 Temel EDA
# ------------------------------------------------------------------
total_orders = df["order_id"].nunique()
total_revenue = df["item_revenue"].sum()
print(f"\nToplam siparis: {total_orders}")
print(f"Toplam gelir: {total_revenue:,.2f}")
print(f"Benzersiz kullanici: {df['user_id'].nunique()}")
print(f"Benzersiz urun: {df['product_id'].nunique()}")
print(f"AOV: {total_revenue / total_orders:,.2f}")

# Aylik gelir trendi
monthly = df.groupby("month").agg(
    revenue=("item_revenue", "sum"),
    orders=("order_id", "nunique"),
).reset_index()
monthly.to_csv(OUT / "monthly_revenue.csv", index=False)

fig, ax = plt.subplots(figsize=(10, 5))
ax.plot(monthly["month"], monthly["revenue"], marker="o", color="#1f77b4")
ax.set_title("Aylik Gelir Trendi (2024)")
ax.set_xlabel("Ay")
ax.set_ylabel("Gelir")
plt.tight_layout()
plt.savefig(OUT / "01_monthly_revenue.png", dpi=150)
plt.close()

# Kategori bazli gelir
cat = (df.groupby("category")
       .agg(revenue=("item_revenue", "sum"), units=("quantity", "sum"))
       .sort_values("revenue", ascending=False).reset_index())
cat.to_csv(OUT / "category_revenue.csv", index=False)

fig, ax = plt.subplots(figsize=(10, 5))
sns.barplot(data=cat, x="revenue", y="category", color="#2ca02c", ax=ax)
ax.set_title("Kategoriye Gore Gelir")
ax.set_xlabel("Gelir")
ax.set_ylabel("")
plt.tight_layout()
plt.savefig(OUT / "02_category_revenue.png", dpi=150)
plt.close()

# Kullanici tipine gore AOV
ut = (df.groupby("user_type")
      .agg(total_revenue=("item_revenue", "sum"),
           total_orders=("order_id", "nunique"))
      .reset_index())
ut["aov"] = ut["total_revenue"] / ut["total_orders"]
ut.to_csv(OUT / "aov_by_user_type.csv", index=False)

fig, axes = plt.subplots(1, 2, figsize=(11, 4.5))
sns.barplot(data=ut, x="user_type", y="aov", color="#ff7f0e", ax=axes[0])
axes[0].set_title("Kullanici Tipine Gore AOV")
sns.barplot(data=ut, x="user_type", y="total_revenue", color="#9467bd", ax=axes[1])
axes[1].set_title("Kullanici Tipine Gore Toplam Gelir")
plt.tight_layout()
plt.savefig(OUT / "03_user_type.png", dpi=150)
plt.close()

# Top 10 urun
name_col = "product_name" if "product_name" in df.columns else "product_id"
top = (df.groupby(name_col)
       .agg(revenue=("item_revenue", "sum"), units=("quantity", "sum"))
       .sort_values("revenue", ascending=False).head(10).reset_index())
top.to_csv(OUT / "top10_products.csv", index=False)
print("\nTop 10 urun:\n", top)

# ------------------------------------------------------------------
# 4.3 RFM Analizi
# ------------------------------------------------------------------
reference_date = orders["order_date"].max() + pd.Timedelta(days=1)

order_totals = df.groupby(["order_id", "user_id", "order_date"],
                          as_index=False)["item_revenue"].sum()

rfm = order_totals.groupby("user_id").agg(
    recency=("order_date", lambda x: (reference_date - x.max()).days),
    frequency=("order_id", "nunique"),
    monetary=("item_revenue", "sum"),
).reset_index()


def score(series, ascending=True):
    """1-5 arasi skor. rank(method='first') ile esit degerlerde hata onlenir."""
    ranked = series.rank(method="first", ascending=ascending)
    return pd.qcut(ranked, 5, labels=[1, 2, 3, 4, 5]).astype(int)


rfm["R"] = score(rfm["recency"], ascending=False)  # az recency = yuksek skor
rfm["F"] = score(rfm["frequency"])
rfm["M"] = score(rfm["monetary"])
rfm["RFM_score"] = rfm["R"].astype(str) + rfm["F"].astype(str) + rfm["M"].astype(str)


def segment(row):
    r, f, m = row["R"], row["F"], row["M"]
    if r >= 4 and f >= 4 and m >= 4:
        return "Champions"
    if f >= 4 and r >= 3:
        return "Loyal Customers"
    if m >= 4 and f <= 3:
        return "Big Spenders"
    if r >= 4 and f <= 2:
        return "New / Promising"
    if r <= 2 and f >= 4:
        return "At Risk"
    if r <= 2 and f <= 2:
        return "Lost / Hibernating"
    return "Need Attention"


rfm["segment"] = rfm.apply(segment, axis=1)

seg = (rfm.groupby("segment")
       .agg(customers=("user_id", "count"),
            avg_recency=("recency", "mean"),
            avg_frequency=("frequency", "mean"),
            avg_monetary=("monetary", "mean"),
            total_revenue=("monetary", "sum"))
       .sort_values("total_revenue", ascending=False).round(2).reset_index())
print("\nRFM segmentleri:\n", seg)

rfm.to_csv(OUT / "rfm_customers.csv", index=False)
seg.to_csv(OUT / "rfm_segments.csv", index=False)

fig, axes = plt.subplots(1, 2, figsize=(13, 5))
sns.barplot(data=seg, x="customers", y="segment", color="#17becf", ax=axes[0])
axes[0].set_title("Segment Bazinda Musteri Sayisi")
axes[0].set_ylabel("")
sns.barplot(data=seg, x="total_revenue", y="segment", color="#d62728", ax=axes[1])
axes[1].set_title("Segment Bazinda Toplam Gelir")
axes[1].set_ylabel("")
plt.tight_layout()
plt.savefig(OUT / "04_rfm_segments.png", dpi=150)
plt.close()

# RFM sorusu: en cok harcayan = en sadik mi?
top_spenders = rfm.nlargest(max(1, len(rfm) // 10), "monetary")["user_id"]
top_loyal = rfm.nlargest(max(1, len(rfm) // 10), "frequency")["user_id"]
overlap = len(set(top_spenders) & set(top_loyal)) / len(top_spenders)
corr = rfm[["recency", "frequency", "monetary"]].corr().round(2)
print(f"\nEn cok harcayan %10 ile en sik alisveris yapan %10 ortusme orani: {overlap:.0%}")
print("Korelasyon:\n", corr)

# Tableau icin birlesik analiz tablosu
df.to_csv(OUT / "analysis_table.csv", index=False)
print("\nBitti. Ciktilar:", OUT)
