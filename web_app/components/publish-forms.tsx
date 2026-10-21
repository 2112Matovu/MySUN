"use client";

import { useRouter } from "next/navigation";
import { useState, useTransition } from "react";
import { Field, FormMessage, Select, TextArea } from "./forms";
import { ImageUpload } from "./ImageUpload";
import { publishContent, saveDraft, type PublishResult } from "@/app/actions/publish";
import {
  ANNOUNCEMENT_CATEGORIES,
  DEPARTMENTS,
  EVENT_CATEGORIES,
  ORGANIZERS,
  isoToSoroti,
  sorotiToIso,
  type ContentType,
  type Submission,
} from "@/lib/publish";

const opts = (xs: string[]) => xs.map((x) => ({ value: x, label: x }));
const str = (v: unknown, d = "") => (typeof v === "string" ? v : d);
const num = (v: unknown) => (typeof v === "number" ? v : undefined);
const pad = (n: number | undefined) => String(n ?? 0).padStart(2, "0");

/** Shared footer: Save draft + Publish/Schedule, with progress and messages. */
function useShell(type: ContentType, draft: Submission | null | undefined) {
  const router = useRouter();
  const [pending, start] = useTransition();
  const [msg, setMsg] = useState<PublishResult>();
  const [draftId, setDraftId] = useState(draft?.id ?? null);

  const run = (kind: "draft" | "publish", title: string, form: Record<string, unknown>, payload: Record<string, unknown>) =>
    start(async () => {
      setMsg(undefined);
      if (!title.trim()) return setMsg({ ok: false, message: "Add a title first." });
      if (kind === "draft") {
        const r = await saveDraft(type, title, form, draftId);
        if (r.ok && r.id) setDraftId(r.id);
        setMsg(r);
      } else {
        const r = await publishContent(type, payload, draftId);
        setMsg(r);
        if (r.ok) setTimeout(() => router.push("/publish"), 1100);
      }
    });
  return { pending, msg, run };
}

function Footer({
  pending,
  msg,
  scheduled,
  publishLabel,
  onDraft,
  onPublish,
}: {
  pending: boolean;
  msg?: PublishResult;
  scheduled?: boolean;
  publishLabel: string;
  onDraft: () => void;
  onPublish: () => void;
}) {
  return (
    <div className="space-y-4 border-t border-line pt-8">
      <FormMessage error={msg && !msg.ok ? msg.message : undefined} notice={msg?.ok ? msg.message : undefined} />
      <div className="flex flex-wrap gap-3">
        <button
          type="button"
          disabled={pending}
          onClick={onPublish}
          className="inline-flex min-h-12 items-center rounded-full bg-night px-8 py-3 font-semibold text-white transition hover:bg-blue disabled:cursor-wait disabled:opacity-60"
        >
          {pending ? "Working…" : scheduled ? "Schedule" : publishLabel}
        </button>
        <button
          type="button"
          disabled={pending}
          onClick={onDraft}
          className="inline-flex min-h-12 items-center rounded-full border border-line bg-paper px-8 py-3 font-semibold transition hover:border-night/40 disabled:opacity-60"
        >
          Save draft
        </button>
      </div>
    </div>
  );
}

function Schedule({ what, value, onChange }: { what: string; value: string | null; onChange: (v: string | null) => void }) {
  const on = value !== null;
  return (
    <div className="rounded-2xl border border-line bg-paper p-5">
      <label className="flex cursor-pointer items-center justify-between gap-4">
        <span>
          <span className="block font-semibold">Schedule for later</span>
          <span className="text-[0.95rem] text-mute">{on ? `${what} goes live at the time below (Soroti time).` : `${what} goes live as soon as you publish.`}</span>
        </span>
        <input
          type="checkbox"
          checked={on}
          onChange={(e) => onChange(e.target.checked ? isoToSoroti(new Date(Date.now() + 3_600_000).toISOString()) : null)}
          className="h-6 w-6 accent-blue"
        />
      </label>
      {on && <Field label="Go live at" type="datetime-local" className="mt-4" value={value ?? ""} onChange={(e) => onChange(e.target.value)} />}
    </div>
  );
}

function when(local: string | null): { iso: string | null; error?: string } {
  if (local === null) return { iso: null };
  const iso = sorotiToIso(local);
  if (!iso || +new Date(iso) < Date.now()) return { iso: null, error: "Pick a go-live time in the future." };
  return { iso };
}

/* ---------------- Announcement ---------------- */

function AnnouncementForm({ draft }: { draft?: Submission | null }) {
  const fd = draft?.form_data ?? {};
  const [title, setTitle] = useState(str(fd.title));
  const [content, setContent] = useState(str(fd.content));
  const [department, setDepartment] = useState(str(fd.department, DEPARTMENTS[0]));
  const [category, setCategory] = useState(str(fd.category, ANNOUNCEMENT_CATEGORIES[0]));
  const [important, setImportant] = useState(Boolean(fd.isImportant));
  const [image, setImage] = useState<string[]>(str(fd.imageUrl) ? [str(fd.imageUrl)] : []);
  const [hasExpiry, setHasExpiry] = useState(Boolean(fd.expiryDate));
  const [expiry, setExpiry] = useState(
    fd.expiryDate ? `${str(fd.expiryDate).slice(0, 10)}T${pad(num(fd.expiryHour) ?? 23)}:${pad(num(fd.expiryMinute) ?? 59)}` : "",
  );
  const [publishAt, setPublishAt] = useState<string | null>(draft?.publish_at ? isoToSoroti(draft.publish_at) : null);
  const [err, setErr] = useState<string>();
  const shell = useShell("announcement", draft);

  const form = () => ({
    title, content, department, category, isImportant: important,
    expiryDate: hasExpiry && expiry ? `${expiry.slice(0, 10)}T00:00:00.000` : null,
    expiryHour: hasExpiry && expiry ? Number(expiry.slice(11, 13)) : null,
    expiryMinute: hasExpiry && expiry ? Number(expiry.slice(14, 16)) : null,
    imageUrl: image[0] ?? null,
    publishAt: publishAt ? sorotiToIso(publishAt) : null,
  });

  const publish = () => {
    setErr(undefined);
    if (!content.trim()) return setErr("Write the announcement text.");
    if (hasExpiry && !expiry) return setErr("Pick an expiry date, or turn expiry off.");
    const s = when(publishAt);
    if (s.error) return setErr(s.error);
    shell.run("publish", title, form(), {
      title: title.trim(), description: content.trim(), category, department, is_important: important,
      image_url: image[0] ?? null, expires_at: hasExpiry ? sorotiToIso(expiry) : null, publish_at: s.iso,
    });
  };

  return (
    <div className="space-y-6">
      <Field label="Title" required value={title} onChange={(e) => setTitle(e.target.value)} maxLength={200} />
      <div className="grid gap-6 sm:grid-cols-2">
        <Select label="Department" value={department} onChange={(e) => setDepartment(e.target.value)} options={opts(DEPARTMENTS)} />
        <Select label="Category" value={category} onChange={(e) => setCategory(e.target.value)} options={opts(ANNOUNCEMENT_CATEGORIES)} />
      </div>
      <TextArea label="Content" required rows={8} value={content} onChange={(e) => setContent(e.target.value)} />
      <label className="flex cursor-pointer items-center gap-3">
        <input type="checkbox" checked={important} onChange={(e) => setImportant(e.target.checked)} className="h-5 w-5 accent-blue" />
        <span><span className="font-semibold">Mark as important</span> <span className="text-mute">(shown first, and sent as a push alert)</span></span>
      </label>
      <ImageUpload label="Photo (optional)" urls={image} onChange={setImage} />
      <div className="rounded-2xl border border-line bg-paper p-5">
        <label className="flex cursor-pointer items-center justify-between gap-4">
          <span>
            <span className="block font-semibold">Set an expiry</span>
            <span className="text-[0.95rem] text-mute">Expired announcements leave the feed automatically.</span>
          </span>
          <input type="checkbox" checked={hasExpiry} onChange={(e) => setHasExpiry(e.target.checked)} className="h-6 w-6 accent-blue" />
        </label>
        {hasExpiry && <Field label="Expires at (Soroti time)" type="datetime-local" className="mt-4" value={expiry} onChange={(e) => setExpiry(e.target.value)} />}
      </div>
      <Schedule what="The announcement" value={publishAt} onChange={setPublishAt} />
      <FormMessage error={err} />
      <Footer pending={shell.pending} msg={shell.msg} scheduled={publishAt !== null} publishLabel="Publish announcement" onDraft={() => shell.run("draft", title, form(), {})} onPublish={publish} />
    </div>
  );
}

/* ---------------- Event ---------------- */

function EventForm({ draft }: { draft?: Submission | null }) {
  const fd = draft?.form_data ?? {};
  const [title, setTitle] = useState(str(fd.title));
  const [description, setDescription] = useState(str(fd.description));
  const [location, setLocation] = useState(str(fd.location));
  const [organizer, setOrganizer] = useState(str(fd.organizer, ORGANIZERS[0]));
  const [category, setCategory] = useState(str(fd.category, EVENT_CATEGORIES[0]));
  const [start, setStart] = useState(fd.startDate ? `${str(fd.startDate).slice(0, 10)}T${pad(num(fd.startHour))}:${pad(num(fd.startMinute))}` : "");
  const [end, setEnd] = useState(fd.startDate && num(fd.endHour) !== undefined ? `${str(fd.startDate).slice(0, 10)}T${pad(num(fd.endHour))}:${pad(num(fd.endMinute))}` : "");
  const [capacity, setCapacity] = useState(str(fd.capacity));
  const [featured, setFeatured] = useState(Boolean(fd.isFeatured));
  const [image, setImage] = useState<string[]>(str(fd.imageUrl) ? [str(fd.imageUrl)] : []);
  const [publishAt, setPublishAt] = useState<string | null>(draft?.publish_at ? isoToSoroti(draft.publish_at) : null);
  const [err, setErr] = useState<string>();
  const shell = useShell("event", draft);

  const form = () => ({
    title, description, location, organizer, category, capacity, isFeatured: featured,
    startDate: start ? `${start.slice(0, 10)}T00:00:00.000` : null,
    startHour: start ? Number(start.slice(11, 13)) : null,
    startMinute: start ? Number(start.slice(14, 16)) : null,
    endHour: end ? Number(end.slice(11, 13)) : null,
    endMinute: end ? Number(end.slice(14, 16)) : null,
    imageUrl: image[0] ?? null,
    publishAt: publishAt ? sorotiToIso(publishAt) : null,
  });

  const publish = () => {
    setErr(undefined);
    if (!description.trim()) return setErr("Describe the event.");
    if (!location.trim()) return setErr("Add the venue.");
    if (!start) return setErr("Pick a start date and time.");
    const startIso = sorotiToIso(start);
    const endIso = end ? sorotiToIso(end) : null;
    if (endIso && startIso && +new Date(endIso) <= +new Date(startIso)) return setErr("The end time must be after the start time.");
    const s = when(publishAt);
    if (s.error) return setErr(s.error);
    const cap = capacity.trim() ? Number(capacity) : null;
    if (cap !== null && (!Number.isInteger(cap) || cap < 1)) return setErr("Capacity must be a whole number, or left empty.");
    shell.run("publish", title, form(), {
      title: title.trim(), description: description.trim(), category, organizer_name: organizer,
      date_time: startIso, end_date_time: endIso, venue: location.trim(), image_url: image[0] ?? null,
      capacity: cap, is_featured: featured, publish_at: s.iso,
    });
  };

  return (
    <div className="space-y-6">
      <Field label="Event title" required value={title} onChange={(e) => setTitle(e.target.value)} maxLength={200} />
      <TextArea label="Description" required rows={6} value={description} onChange={(e) => setDescription(e.target.value)} />
      <div className="grid gap-6 sm:grid-cols-2">
        <Field label="Starts (Soroti time)" type="datetime-local" required value={start} onChange={(e) => setStart(e.target.value)} />
        <Field label="Ends (optional)" type="datetime-local" value={end} onChange={(e) => setEnd(e.target.value)} />
      </div>
      <Field label="Venue" required value={location} onChange={(e) => setLocation(e.target.value)} />
      <div className="grid gap-6 sm:grid-cols-2">
        <Select label="Organiser" value={organizer} onChange={(e) => setOrganizer(e.target.value)} options={opts(ORGANIZERS)} />
        <Select label="Category" value={category} onChange={(e) => setCategory(e.target.value)} options={opts(EVENT_CATEGORIES)} />
      </div>
      <Field label="Places (optional)" inputMode="numeric" value={capacity} onChange={(e) => setCapacity(e.target.value.replace(/\D/g, ""))} hint="Leave empty for no limit." />
      <label className="flex cursor-pointer items-center gap-3">
        <input type="checkbox" checked={featured} onChange={(e) => setFeatured(e.target.checked)} className="h-5 w-5 accent-blue" />
        <span className="font-semibold">Feature this event</span>
      </label>
      <ImageUpload label="Poster (optional)" urls={image} onChange={setImage} />
      <Schedule what="The event" value={publishAt} onChange={setPublishAt} />
      <FormMessage error={err} />
      <Footer pending={shell.pending} msg={shell.msg} scheduled={publishAt !== null} publishLabel="Publish event" onDraft={() => shell.run("draft", title, form(), {})} onPublish={publish} />
    </div>
  );
}

/* ---------------- Housing ---------------- */

function AccommodationForm({ draft }: { draft?: Submission | null }) {
  const fd = draft?.form_data ?? {};
  const [name, setName] = useState(str(fd.name));
  const [type, setType] = useState(str(fd.type, "hostel"));
  const [location, setLocation] = useState(str(fd.location));
  const [price, setPrice] = useState(str(fd.price));
  const [gazetted, setGazetted] = useState(Boolean(fd.isGazetted));
  const [sharing, setSharing] = useState(str(fd.roomSharing, "shared"));
  const [phone, setPhone] = useState(str(fd.phone));
  const [description, setDescription] = useState(str(fd.description));
  const [images, setImages] = useState<string[]>(Array.isArray(fd.images) ? (fd.images as string[]) : []);
  const [err, setErr] = useState<string>();
  const shell = useShell("accommodation", draft);

  const form = () => ({ name, type, location, price, isGazetted: gazetted, roomSharing: sharing, phone, description, images });

  const publish = () => {
    setErr(undefined);
    const p = Number(price);
    if (!location.trim()) return setErr("Add the location.");
    if (!Number.isInteger(p) || p <= 0) return setErr("Enter the price as a whole number of UGX.");
    if (!phone.trim()) return setErr("Add a contact phone number.");
    shell.run("publish", name, form(), {
      name: name.trim(), type, location: location.trim(), price: p, is_gazetted: gazetted,
      room_sharing: sharing, contact_phone: phone.trim(), image_urls: images, description: description.trim() || null,
    });
  };

  return (
    <div className="space-y-6">
      <Field label="Hostel or rental name" required value={name} onChange={(e) => setName(e.target.value)} />
      <div className="grid gap-6 sm:grid-cols-2">
        <Select label="Type" value={type} onChange={(e) => setType(e.target.value)} options={[{ value: "hostel", label: "Hostel" }, { value: "rental", label: "Rental" }]} />
        <Select label="Room sharing" value={sharing} onChange={(e) => setSharing(e.target.value)} options={[{ value: "shared", label: "Shared rooms" }, { value: "private", label: "Private rooms" }, { value: "both", label: "Shared and private" }]} />
      </div>
      <Field label="Location" required value={location} onChange={(e) => setLocation(e.target.value)} placeholder="5 min walk from Main Gate" />
      <Field label={`Price per ${type === "hostel" ? "semester" : "month"} (UGX)`} required inputMode="numeric" value={price} onChange={(e) => setPrice(e.target.value.replace(/\D/g, ""))} />
      <label className="flex cursor-pointer items-center gap-3">
        <input type="checkbox" checked={gazetted} onChange={(e) => setGazetted(e.target.checked)} className="h-5 w-5 accent-blue" />
        <span className="font-semibold">Gazetted by the university</span>
      </label>
      <Field label="Contact phone" required type="tel" value={phone} onChange={(e) => setPhone(e.target.value)} />
      <TextArea label="Description" rows={4} value={description} onChange={(e) => setDescription(e.target.value)} />
      <ImageUpload label="Photos" urls={images} onChange={setImages} max={6} hint="Up to 6 photos. The first one is the cover." />
      <FormMessage error={err} />
      <Footer pending={shell.pending} msg={shell.msg} publishLabel="Publish listing" onDraft={() => shell.run("draft", name, form(), {})} onPublish={publish} />
    </div>
  );
}

/* ---------------- Boda rider ---------------- */

function TransportForm({ draft }: { draft?: Submission | null }) {
  const fd = draft?.form_data ?? {};
  const [name, setName] = useState(str(fd.name));
  const [phone, setPhone] = useState(str(fd.phone));
  const [person, setPerson] = useState(str(fd.contactPerson));
  const [hours, setHours] = useState(str(fd.operatingHours));
  const [areas, setAreas] = useState(str(fd.serviceAreas));
  const [image, setImage] = useState<string[]>(str(fd.imageUrl) ? [str(fd.imageUrl)] : []);
  const [err, setErr] = useState<string>();
  const shell = useShell("transport", draft);

  const form = () => ({ name, phone, contactPerson: person, operatingHours: hours, serviceAreas: areas, imageUrl: image[0] ?? null });

  const publish = () => {
    setErr(undefined);
    if (!phone.trim()) return setErr("Add a phone number.");
    shell.run("publish", name, form(), {
      name: name.trim(), phone_number: phone.trim(), contact_person: person.trim() || null,
      operating_hours: hours.trim() || null, service_areas: areas.split(",").map((a) => a.trim()).filter(Boolean),
      image_url: image[0] ?? null,
    });
  };

  return (
    <div className="space-y-6">
      <Field label="Rider or stage name" required value={name} onChange={(e) => setName(e.target.value)} />
      <Field label="Phone number" required type="tel" value={phone} onChange={(e) => setPhone(e.target.value)} />
      <Field label="Contact person" value={person} onChange={(e) => setPerson(e.target.value)} />
      <Field label="Operating hours" value={hours} onChange={(e) => setHours(e.target.value)} placeholder="6:00 AM - 9:00 PM" />
      <Field label="Service areas" value={areas} onChange={(e) => setAreas(e.target.value)} hint="Separate places with commas, for example Main Gate, Soroti Town." />
      <ImageUpload label="Photo (optional)" urls={image} onChange={setImage} />
      <FormMessage error={err} />
      <Footer pending={shell.pending} msg={shell.msg} publishLabel="Publish rider" onDraft={() => shell.run("draft", name, form(), {})} onPublish={publish} />
    </div>
  );
}

export function PublishForm({ type, draft }: { type: ContentType; draft?: Submission | null }) {
  switch (type) {
    case "announcement":
      return <AnnouncementForm draft={draft} />;
    case "event":
      return <EventForm draft={draft} />;
    case "accommodation":
      return <AccommodationForm draft={draft} />;
    case "transport":
      return <TransportForm draft={draft} />;
  }
}
