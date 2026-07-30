package com.tomerikheggedal.vitola.data

import android.app.Activity
import android.content.Context
import com.revenuecat.purchases.LogLevel
import com.revenuecat.purchases.Offering
import com.revenuecat.purchases.Package
import com.revenuecat.purchases.PurchaseParams
import com.revenuecat.purchases.Purchases
import com.revenuecat.purchases.PurchasesConfiguration
import com.revenuecat.purchases.PurchasesTransactionException
import com.revenuecat.purchases.awaitCustomerInfo
import com.revenuecat.purchases.awaitOfferings
import com.revenuecat.purchases.awaitPurchase
import com.revenuecat.purchases.awaitRestore
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

// MARK: - Pro-konfig (speiler iOS ProConfig)
//
// Samme entitlement «SEDER Pro» og offering «default» som iOS, slik at
// RevenueCat serverer riktige Play-produkter (seder_pro_monthly/_yearly) på
// Android. Den publiserbare Google-SDK-nøkkelen (goog_...) genereres når
// Android-appen legges til i RevenueCat — lim den inn under.
object ProConfig {
    const val revenueCatApiKey = "goog_LIM_INN_HER"
    const val entitlementId = "SEDER Pro"
    const val foundingCode = "SEDER100"
    const val foundingCap = 100

    val isConfigured: Boolean
        get() = revenueCatApiKey.startsWith("goog_") && !revenueCatApiKey.contains("LIM_INN")
}

// MARK: - ProManager (speiler iOS ProManager)
//
// Global kilde til Pro-status. isPro = aktivt abonnement ELLER founding member
// (livstids-Pro for de 100 første), med mindre DEBUG-bryteren tvinger gratis.
object ProManager {

    private val _isPro = MutableStateFlow(false)
    val isPro: StateFlow<Boolean> = _isPro.asStateFlow()

    // DEBUG: la tidlig-tester/founding member se paywallen for å teste kjøp.
    var debugForceFree: Boolean = false
        set(value) { field = value; recompute() }

    private var isSubscriber = false
    private var isFoundingMember = false

    fun configure(context: Context) {
        if (!ProConfig.isConfigured) return
        Purchases.logLevel = LogLevel.WARN
        Purchases.configure(
            PurchasesConfiguration.Builder(context, ProConfig.revenueCatApiKey).build()
        )
    }

    private fun recompute() {
        _isPro.value = (isSubscriber || isFoundingMember) && !debugForceFree
    }

    /// Founding member settes fra ProfileRepository.claimFoundingNumber-flyten.
    fun setFoundingMember(value: Boolean) {
        isFoundingMember = value
        recompute()
    }

    /// Oppdater abonnementsstatus fra RevenueCat (kall ved oppstart + etter kjøp).
    suspend fun refresh() {
        if (!ProConfig.isConfigured) return
        try {
            val info = Purchases.sharedInstance.awaitCustomerInfo()
            isSubscriber = info.entitlements[ProConfig.entitlementId]?.isActive == true
            recompute()
        } catch (_: Exception) {
            // Nettverksfeil o.l. — behold forrige status.
        }
    }

    /// Gjeldende offering («default») med årlig/månedlig pakker.
    suspend fun currentOffering(): Offering? {
        if (!ProConfig.isConfigured) return null
        return try {
            Purchases.sharedInstance.awaitOfferings().current
        } catch (_: Exception) {
            null
        }
    }

    enum class PurchaseOutcome { SUCCESS, CANCELLED, FAILED }

    suspend fun purchase(activity: Activity, pkg: Package): PurchaseOutcome {
        if (!ProConfig.isConfigured) return PurchaseOutcome.FAILED
        return try {
            val result = Purchases.sharedInstance.awaitPurchase(
                PurchaseParams.Builder(activity, pkg).build()
            )
            isSubscriber = result.customerInfo.entitlements[ProConfig.entitlementId]?.isActive == true
            recompute()
            PurchaseOutcome.SUCCESS
        } catch (e: PurchasesTransactionException) {
            if (e.userCancelled) PurchaseOutcome.CANCELLED else PurchaseOutcome.FAILED
        } catch (_: Exception) {
            PurchaseOutcome.FAILED
        }
    }

    /// Gjenopprett tidligere kjøp. Returnerer true hvis Pro er aktivt etterpå.
    suspend fun restore(): Boolean {
        if (!ProConfig.isConfigured) return false
        return try {
            val info = Purchases.sharedInstance.awaitRestore()
            isSubscriber = info.entitlements[ProConfig.entitlementId]?.isActive == true
            recompute()
            isSubscriber
        } catch (_: Exception) {
            false
        }
    }
}
